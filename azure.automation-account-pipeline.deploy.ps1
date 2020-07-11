# Deploy modules from a public repository
Deploy PSDepend {
    By AzureAutomationModule {
        FromSource "https://www.powershellgallery.com/api/v2"
        To "aademo-aa-73xuwp74ekl6a"
        WithOptions @{
            SourceIsAbsolute  = $true
            ModuleName        = "PSDepend"
            ResourceGroupName = "aademo-rg-65pwanldm3ese"
            # Force             = $true # If you what to override an existing module
        }
    }
}

Deploy PackageManagement {
    By AzureAutomationModule {
        FromSource "https://www.powershellgallery.com/api/v2"
        To "aademo-aa-73xuwp74ekl6a"
        WithOptions @{
            SourceIsAbsolute  = $true
            ModuleName        = "PackageManagement"
            ModuleVersion     = '1.4.7'
            ResourceGroupName = "aademo-rg-65pwanldm3ese"
        }
    }
}

# Deploy a DSC configuration
Deploy hybridWorkerConfiguration {
    By AzureAutomationDscConfiguration {
        FromSource "build\dsc-configurations\hybridWorkerConfiguration.ps1"
        To "aademo-aa-73xuwp74ekl6a"
        WithOptions @{
            ResourceGroupName = "aademo-rg-65pwanldm3ese"
            Published         = $true
            Force             = $true
            Compile           = $true
            ConfigurationData = @{
                # Node specific data
                AllNodes = @(
                    @{NodeName   = "localhost";
                        Modules  = @(
                            "PSDepend"
                        )
                    }
                );
            }
        }
        DependingOn PackageManagement
    }
}

# Deploy an Azure Automation runbook
Deploy Get-ExecutionContextInfo {
    By AzureAutomationRunbook {
        FromSource "build\runbooks\Get-ExecutionContextInfo.ps1"
        To "aademo-aa-73xuwp74ekl6a"
        WithOptions @{
            RunbookName       = "Get-ExecutionContextInfo"
            ResourceGroupName = "aademo-rg-65pwanldm3ese"
            Force             = $true
        }
        DependingOn PSDepend, hybridWorkerConfiguration
    }
}