@{
    #region Build dependencies
    Pester           = @{ target = 'CurrentUser'; version = '4.10.1' } # Using version 4 due to the breaking changes in version 5
    PSScriptAnalyzer = @{ target = 'CurrentUser'; version = 'latest' }
    #endregion Build dependencies
}