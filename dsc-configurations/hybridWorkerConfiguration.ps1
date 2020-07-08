Configuration hybridWorkerConfiguration {

    #Importing required DSC resources
    Import-DscResource -ModuleName @{ModuleName = "PackageManagement"; RequiredVersion = "1.4.7"}
    Import-DscResource -ModuleName PSDesiredStateConfiguration


    Node $AllNodes.NodeName {

        #region Ensuring that PowerShell Gallery is a registered repository
        PackageManagementSource PSGallery {
            Ensure             = "Present"
            Name               = "PSGallery"
            ProviderName       = "PowerShellGet"
            SourceLocation     = "https://www.powershellgallery.com/api/v2"
            InstallationPolicy = "Trusted"
        }

        Log PSGalleryConfigured {
            Message   = "PSGallery source for PowerShell modules configured."
            DependsOn = "[PackageManagementSource]PSGallery"
        }
        #endregion

        #region Ensuring that the PowerShell modules specified in the configuration data are installed
        $Node.modules.foreach(
            {
                PackageManagement $_ {
                    Name      = $_
                    Ensure    = "Present"
                    Source    = "PSGallery"
                    DependsOn = "[PackageManagementSource]PSGallery"

                }

                Log ("Module" + $_ + "Installed") {
                    Message   = "PowerShell modules " + $_ + " has been successfully installed."
                    DependsOn = ("[PackageManagement]" + $_)
                }
            }
        )
        #endregion

    }
}