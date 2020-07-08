#requires -modules InvokeBuild

<#
.SYNOPSIS
    Build script (https://github.com/nightroman/Invoke-Build)

.DESCRIPTION
    This script contains the tasks for testing and analyzing the PowerShell runbooks and DSC configurations

#>

Param (
    # Personal Access Token to be used by PSDepend if accessing private PowerShell repositories
    [Parameter(Mandatory = $false, ValueFromPipelineByPropertyName = $true)]
    [ValidateNotNullOrEmpty()]
    [String]
    $PAT
)

Set-StrictMode -Version Latest

# Default invocation tasks - perform clean build
task . Clean, Test, Analyze, Build

# Setting build script variables
$buildOutputPath = Join-Path -Path $BuildRoot -ChildPath 'build'

$runbookFolderName = 'runbooks'
$runbookFolderPath = Join-Path -Path $BuildRoot -ChildPath $runbookFolderName
$runbookOutputPath = Join-Path -Path $buildOutputPath -ChildPath $runbookFolderName

$dscFolderName = 'dsc-configurations'
$dscFolderPath = Join-Path -Path $BuildRoot -ChildPath $dscFolderName
$dscOutputPath = Join-Path -Path $buildOutputPath -ChildPath $dscFolderName

# Install build dependencies
Enter-Build {
    if (-not (Get-Module -Name PSDepend -ListAvailable)) {
        Install-Module PSDepend -Force
    }
    Import-Module PSDepend
    # Set access token to be used for dependency handling
    if ($PAT) {
        $env:PAT = $PAT # Export to environment variable to be referenced in PSDepend configuration
    }
    Invoke-PSDepend -Force
}

# Synopsis: Analyze the project with PSScriptAnalyzer
task Analyze {
    # Get-ChildItem parameters
    $Params = @{
        Path    = $BuildRoot
        Recurse = $true
        Include = "*.PSSATests.*"
    }

    $TestFiles = Get-ChildItem @Params

    # Pester parameters
    $Params = @{
        Path     = $TestFiles
        PassThru = $true
    }

    # Additional parameters on Azure Pipelines agents to generate test results
    if ($env:TF_BUILD) {
        if (-not (Test-Path -Path $buildOutputPath -ErrorAction SilentlyContinue)) {
            New-Item -Path $buildOutputPath -ItemType Directory
        }
        $Timestamp = Get-date -UFormat "%Y%m%d-%H%M%S"
        $PSVersion = $PSVersionTable.PSVersion.Major
        $TestResultFile = "AnalysisResults_PS$PSVersion`_$TimeStamp.xml"
        $Params.Add("OutputFile", "$buildOutputPath\$TestResultFile")
        $Params.Add("OutputFormat", "NUnitXml")
    }

    # Invoke all tests
    $TestResults = Invoke-Pester @Params
    if ($TestResults.FailedCount -gt 0) {
        $TestResults | Format-List
        throw 'One or more PSScriptAnalyzer rules have been violated. Build cannot continue!'
    }
}

# Synopsis: Test the project with Pester tests
task Test {
    # Get-ChildItem parameters
    $Params = @{
        Path    = $BuildRoot
        Recurse = $true
        Include = "*.Tests.*"
    }

    $TestFiles = Get-ChildItem @Params

    # Pester parameters
    $Params = @{
        Path     = $TestFiles
        PassThru = $true
    }

    # Additional parameters on Azure Pipelines agents to generate test results
    if ($env:TF_BUILD) {
        if (-not (Test-Path -Path $buildOutputPath -ErrorAction SilentlyContinue)) {
            New-Item -Path $buildOutputPath -ItemType Directory
        }
        $Timestamp = Get-date -UFormat "%Y%m%d-%H%M%S"
        $PSVersion = $PSVersionTable.PSVersion.Major
        $TestResultFile = "TestResults_PS$PSVersion`_$TimeStamp.xml"
        $Params.Add("OutputFile", "$buildOutputPath\$TestResultFile")
        $Params.Add("OutputFormat", "NUnitXml")
    }

    # Invoke all tests
    $TestResults = Invoke-Pester @Params
    if ($TestResults.FailedCount -gt 0) {
        $TestResults | Format-List
        throw 'One or more Pester tests have failed. Build cannot continue!'
    }
}

# Synopsis: Verify the code coverage by tests
task CodeCoverage {
    $acceptableCodeCoveragePercent = 60

    # Get-ChildItem parameters
    $Params = @{
        Path    = $runbookFolderPath
        Recurse = $true
        Include = '*.ps1'
        Exclude = '*.Tests.ps1', '*.PSSATests.ps1'
    }

    $TestFiles = Get-ChildItem @Params

    # Pester parameters
    $Params = @{
        Path         = $runbookFolderPath
        CodeCoverage = $TestFiles
        PassThru     = $true
        Show         = 'Summary'
    }

    # Additional parameters on Azure Pipelines agents to generate code coverage report
    if ($env:TF_BUILD) {
        if (-not (Test-Path -Path $buildOutputPath -ErrorAction SilentlyContinue)) {
            New-Item -Path $buildOutputPath -ItemType Directory
        }
        $Timestamp = Get-date -UFormat "%Y%m%d-%H%M%S"
        $PSVersion = $PSVersionTable.PSVersion.Major
        $TestResultFile = "CodeCoverageResults_PS$PSVersion`_$TimeStamp.xml"
        $Params.Add("CodeCoverageOutputFile", "$buildOutputPath\$TestResultFile")
    }

    $result = Invoke-Pester @Params

    If ( $result.CodeCoverage ) {
        $codeCoverage = $result.CodeCoverage
        $commandsFound = $codeCoverage.NumberOfCommandsAnalyzed

        # To prevent any "Attempted to divide by zero" exceptions
        If ( $commandsFound -ne 0 ) {
            $commandsExercised = $codeCoverage.NumberOfCommandsExecuted
            [System.Double]$actualCodeCoveragePercent = [Math]::Round(($commandsExercised / $commandsFound) * 100, 2)
        }
        Else {
            [System.Double]$actualCodeCoveragePercent = 0
        }
    }

    # Fail the task if the code coverage results are not acceptable
    if ($actualCodeCoveragePercent -lt $acceptableCodeCoveragePercent) {
        throw "The overall code coverage by Pester tests is $actualCodeCoveragePercent% which is less than quality gate of $acceptableCodeCoveragePercent%. Pester version is: $((Get-Module -Name Pester -ListAvailable).Version)."
    }
}

# Synopsis: Build the project
task Build {
    #region Copy runbooks
    if (-not (Test-Path -Path $runbookOutputPath -ErrorAction SilentlyContinue)) {
        New-Item -Path $runbookOutputPath -ItemType Directory
    }

    Get-ChildItem -Path $runbookFolderPath -Filter '*.ps1' -Recurse | Where-Object -Property Name -notlike '*Tests.ps1' | Copy-Item -Destination $runbookOutputPath
    #endregion Copy runbooks

    #region Copy DSC configurations
    if (-not (Test-Path -Path $dscOutputPath -ErrorAction SilentlyContinue)) {
        New-Item -Path $dscOutputPath -ItemType Directory
    }

    Get-ChildItem -Path $dscFolderPath -Filter '*.ps1' -Recurse | Where-Object -Property Name -notlike '*Tests.ps1' | Copy-Item -Destination $dscOutputPath
    #endregion Copy DSC configurations
}

# Synopsis: Clean up the target build directory
task Clean {
    if (Test-Path $buildOutputPath) {
        Remove-Item –Path $buildOutputPath –Recurse
    }
}