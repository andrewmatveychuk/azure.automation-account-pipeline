$here = Split-Path -Parent $MyInvocation.MyCommand.Path

#region Defining the runbooks to analyze
$runbookPaths = @()
if (Test-Path -Path "$here\**\*.ps1") {
    $runbookPaths += Get-ChildItem -Path "$here\**\*.ps1" -Exclude "*.Tests.ps1"
}
#endregion

# Running the analysis for each function
foreach ($runbookPath in $runbookPaths) {
    $runbookName = $runbookPath.BaseName

    Describe "'$runbookName' analysis with PSScriptAnalyzer" {
        Context 'Standard Rules' {
            # Define PSScriptAnalyzer rules
            $scriptAnalyzerRules = Get-ScriptAnalyzerRule # Just getting all default rules

            # Perform analysis against each rule
            forEach ($rule in $scriptAnalyzerRules) {
                It "should pass '$rule' rule" {
                    Invoke-ScriptAnalyzer -Path $runbookPath -IncludeRule $rule | Should -BeNullOrEmpty
                }
            }
        }
    }
}