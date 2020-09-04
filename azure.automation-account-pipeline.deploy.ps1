# Deploy modules from a public repository
Deploy PSDepend {
    By AzureAutomationModule {
        FromSource "https://www.powershellgallery.com/api/v2"
        To "aademo-aa-2d6feraanlyem"
        WithOptions @{
            SourceIsAbsolute  = $true
            ModuleName        = "PSDepend"
            ResourceGroupName = "aademo-rg-wijiqagxjnoja"
            # Force             = $true # If you what to override an existing module
        }
    }
}

Deploy PackageManagement {
    By AzureAutomationModule {
        FromSource "https://www.powershellgallery.com/api/v2"
        To "aademo-aa-2d6feraanlyem"
        WithOptions @{
            SourceIsAbsolute  = $true
            ModuleName        = "PackageManagement"
            ModuleVersion     = '1.4.7'
            ResourceGroupName = "aademo-rg-wijiqagxjnoja"
        }
    }
}

# Deploy a DSC configuration
Deploy hybridWorkerConfiguration {
    By AzureAutomationDscConfiguration {
        FromSource "build\dsc-configurations\hybridWorkerConfiguration.ps1"
        To "aademo-aa-2d6feraanlyem"
        WithOptions @{
            ResourceGroupName = "aademo-rg-wijiqagxjnoja"
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
        To "aademo-aa-2d6feraanlyem"
        WithOptions @{
            RunbookName       = "Get-ExecutionContextInfo"
            ResourceGroupName = "aademo-rg-wijiqagxjnoja"
            Force             = $true
        }
        DependingOn PSDepend, hybridWorkerConfiguration
    }
}