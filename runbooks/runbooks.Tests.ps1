$here = Split-Path -Parent $MyInvocation.MyCommand.Path

#region Defining the runbooks to test
$runbookPaths = @()
if (Test-Path -Path "$here\**\*.ps1") {
  $runbookPaths += Get-ChildItem -Path "$here\**\*.ps1" -Exclude "*.Tests.ps1"
}
#endregion


# Running the tests for each runbook
foreach ($runbookPath in $runbookPaths) {

  $runbookName = $runbookPath.BaseName

  Describe "'$runbookName' Tests" {
    Context "Code Style Tests" {
      It "should have 'CmdletBinding' attribute" {
        $runbookPath | Should -FileContentMatch 'CmdletBinding'
      }

      It "should have 'Param' attribute" {
        $runbookPath | Should -FileContentMatch 'Param'
      }

      It "should implement 'Begin', 'Process' and 'End' blocks" {
        $runbookPath | Should -FileContentMatch 'Begin'
        $runbookPath | Should -FileContentMatch 'Process'
        $runbookPath | Should -FileContentMatch 'End'
      }

      It "should contain Write-Verbose blocks" {
        $runbookPath | Should -FileContentMatch 'Write-Verbose'
      }

      It "should be a valid PowerShell code" {
        $psFile = Get-Content -Path $runbookPath -ErrorAction Stop
        $errors = $null
        $null = [System.Management.Automation.PSParser]::Tokenize($psFile, [ref]$errors)
        $errors.Count | Should -Be 0
      }

      It "should have tests" {
        Test-Path ($runbookPath -replace ".ps1", ".Tests.ps1") | Should -Be $true
      }

      It "should be tested for start time" {
        ($runbookPath -replace ".ps1", ".Tests.ps1") | Should -FileContentMatch "`$result[0] | Should -Match 'Runbook started at time'"
      }

      It "should be tested for end time" {
        ($runbookPath -replace ".ps1", ".Tests.ps1") | Should -FileContentMatch "`$result[-1] | Should -Match 'Runbook ended at time'"
      }
    }

    Context "Help Quality Tests" {
      # Getting script help
      $parsedScript = [System.Management.Automation.Language.Parser]::ParseInput((Get-Content -raw $runbookPath), [ref]$null, [ref]$null)
      $help = $parsedScript.GetHelpContent()

      It "should have a SYNOPSIS" {
        $help.Synopsis | Should -Not -BeNullOrEmpty
      }

      It "should have a DESCRIPTION with length > 40 symbols" {
        $help.Description.Length | Should -BeGreaterThan 20
      }

      It "should have at least one EXAMPLE" {
        $help.Examples.Count | Should -BeGreaterThan 0
        $help.Examples[0] | Should -Match ([regex]::Escape($runbookName))
        # $help.Examples[0].Length | Should -BeGreaterThan ($runbookName.Length + 10) # Can be used ensure it has descriptive content
      }

      # Getting the list of parameters
      $parameters = $parsedScript.ParamBlock.Parameters.ForEach{ $_.Name.VariablePath.ToString() }

      foreach ($parameter in $parameters) {
        It "should have descriptive help for '$parameter' parameter" {
          $help.Parameters.($parameter.ToUpper()) | Should -Not -BeNullOrEmpty
          $help.Parameters.($parameter.ToUpper()).Length | Should -BeGreaterThan 25
        }
      }

      It "should define INPUTS" {
        $help.Inputs | Should -Not -BeNullOrEmpty
      }

      It "should define OUTPUTS" {
        $help.Outputs | Should -Not -BeNullOrEmpty
      }
    }
  }
}
