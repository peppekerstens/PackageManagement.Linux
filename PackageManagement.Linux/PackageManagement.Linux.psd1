#
# Module manifest for module 'PackageManagement.Linux'
#

@{
    RootModule        = 'PackageManagement.Linux.psm1'
    ModuleVersion     = '0.1.0'
    GUID              = '337abb6f-644a-4af7-88e9-17c554707825'
    Author            = 'Peppe Kerstens'
    CompanyName       = ''
    Copyright         = '(c) Peppe Kerstens. GPL-3.0 license.'
    Description       = 'PowerShell module for Linux providing cmdlet parity with the Windows PackageManagement module. Wraps apt/dnf/zypper to implement Find-Package, Get-Package, Install-Package, Uninstall-Package, and Get-PackageSource.'
    PowerShellVersion = '7.2'
    RequiredModules   = @()

    FunctionsToExport = @(
        'Find-Package',
        'Get-Package',
        'Get-PackageSource',
        'Install-Package',
        'Uninstall-Package'
    )

    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()

    PrivateData = @{
        PSData = @{
            Tags         = @('Linux', 'PackageManagement', 'apt', 'dnf', 'zypper', 'CrossPlatform')
            LicenseUri   = 'https://github.com/peppekerstens/PackageManagement.Linux/blob/main/LICENSE'
            ProjectUri   = 'https://github.com/peppekerstens/PackageManagement.Linux'
            ReleaseNotes = @'
0.1.0 - Initial release. Find-Package (apt-cache/dnf/zypper se), Get-Package (dpkg-query/rpm/zypper), Install-Package, Uninstall-Package (sudo apt-get/dnf/zypper), Get-PackageSource (sources.list/dnf repolist/zypper repos). Auto-detects package manager.
'@
        }
    }
}
