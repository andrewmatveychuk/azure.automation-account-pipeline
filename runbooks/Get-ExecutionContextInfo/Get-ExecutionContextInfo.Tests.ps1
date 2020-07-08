$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path) -replace '\.Tests\.', '.'
# . "$here\$sut"

Describe "Get-ExecutionContextInfo" {
    #region Act
    $result = $(."$here\$sut" -Verbose) 4>&1
    #endregion Act

    #region Assert
    It "should output runbook start time in Verbose mode" {
        $result[0] | Should -Match 'Runbook started at time'
    }

    It "should output runbook end time in Verbose mode" {
        $result[-1] | Should -Match 'Runbook ended at time'
    }

    It "should output into the pipeline" {
        $result = $(."$here\$sut")
        $result | Should -Not -BeNullOrEmpty
    }
    #endregion Assert
}
