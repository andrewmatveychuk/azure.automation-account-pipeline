<#
.SYNOPSIS
    Gets basic info about the runbook execution context
.DESCRIPTION
    The Get-ExecutionContextInfo runbook outputs the basic information such as PowerShell and OS versions, computer name,
    and the list of installed PowerShell modules.

    The runbook has a fake dependency on PSDepend module for demo purposes
.EXAMPLE
    .\Get-ExecutionContextInfo.ps1
.INPUTS
    None
.OUTPUTS
    PSCustomObject
.NOTES
    Author: Andrew Matveychuk
    Email: andrew@andrewmatveychuk.com
#>

#Requires -Modules PSDepend
[CmdletBinding()]
param ()

begin {
    Write-Verbose "Runbook started at time: $(Get-Date -Format R)"
}

process {
    $result = [PSCustomObject]@{
        PowerShellVersion = $PSVersionTable.PSVersion
        OS                = $PSVersionTable.OS
        ComputerName      = $env:COMPUTERNAME
        InstalledModules  = $(Get-Module -ListAvailable)
    }
    Write-Output $result
}

end {
    Write-Verbose "Runbook ended at time: $(Get-Date -Format R)"
}
