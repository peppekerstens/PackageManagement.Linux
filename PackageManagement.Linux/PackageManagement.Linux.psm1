#Requires -Version 7.2

# PackageManagement.Linux.psm1
# Root module for PackageManagement.Linux.
# Dot-sources all function files from the Functions\ subdirectory.

# Linux-only guard — this module wraps Linux package managers (apt, dnf, zypper) and must
# not be loaded on Windows. On Windows, use the built-in PackageManagement module instead:
#   Import-Module PackageManagement
if (-not $IsLinux) {
    throw (
        "PackageManagement.Linux cannot be loaded on Windows. " +
        "On Windows, use the built-in 'PackageManagement' module: Import-Module PackageManagement`n" +
        "PackageManagement.Linux is a Linux-only peer module that wraps apt/dnf/zypper."
    )
}

Get-ChildItem -Path "$PSScriptRoot\Functions" -Filter '*.ps1' |
    Where-Object { $_.Name -notlike '*.Tests.ps1' } |
    ForEach-Object { . $_.FullName }
