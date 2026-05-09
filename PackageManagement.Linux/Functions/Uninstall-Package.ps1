function Uninstall-Package {
    <#
    .Synopsis
        Uninstalls one or more packages via the system package manager.
    .Description
        On Debian/Ubuntu systems, wraps 'sudo apt-get remove -y'. On RHEL/Fedora,
        wraps 'sudo dnf remove -y'. On openSUSE, wraps 'sudo zypper remove -y'.
        Requires sudo/root privileges.
    .Parameter Name
        The name(s) of the package(s) to uninstall. Required.
    .Parameter ProviderName
        The package provider to use: 'apt', 'dnf', or 'zypper'. Auto-detected if omitted.
    .Link
        https://learn.microsoft.com/powershell/module/packagemanagement/uninstall-package
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    [OutputType([void])]
    param(
        [Parameter(Mandatory = $true, Position = 0, ValueFromPipeline = $true)]
        [string[]]$Name,

        [Parameter()]
        [ValidateSet('apt', 'dnf', 'zypper')]
        [string]$ProviderName
    )
    process {
        $provider = $ProviderName
        if (-not $provider) {
            if (Get-Command apt-get -ErrorAction SilentlyContinue)  { $provider = 'apt' }
            elseif (Get-Command dnf -ErrorAction SilentlyContinue)  { $provider = 'dnf' }
            elseif (Get-Command zypper -ErrorAction SilentlyContinue){ $provider = 'zypper' }
            else {
                Write-Error 'Uninstall-Package: No supported package manager found (apt-get/dnf/zypper).'
                return
            }
        }

        foreach ($pkg in $Name) {
            if (-not $PSCmdlet.ShouldProcess($pkg, "Uninstall package via $provider")) { continue }

            switch ($provider) {
                'apt' {
                    $result = & sudo apt-get remove -y $pkg 2>&1
                    if ($LASTEXITCODE -ne 0) { Write-Error "Uninstall-Package: apt-get remove failed for '$pkg': $result" }
                }
                'dnf' {
                    $result = & sudo dnf remove -y $pkg 2>&1
                    if ($LASTEXITCODE -ne 0) { Write-Error "Uninstall-Package: dnf remove failed for '$pkg': $result" }
                }
                'zypper' {
                    $result = & sudo zypper remove -y $pkg 2>&1
                    if ($LASTEXITCODE -ne 0) { Write-Error "Uninstall-Package: zypper remove failed for '$pkg': $result" }
                }
            }
        }
    }
}
