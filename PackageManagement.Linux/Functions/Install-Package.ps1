function Install-Package {
    <#
    .Synopsis
        Installs one or more packages via the system package manager.
    .Description
        On Debian/Ubuntu systems, wraps 'sudo apt-get install -y'. On RHEL/Fedora,
        wraps 'sudo dnf install -y'. On openSUSE, wraps 'sudo zypper install -y'.
        Requires sudo/root privileges.
    .Parameter Name
        The name(s) of the package(s) to install. Required.
    .Parameter ProviderName
        The package provider to use: 'apt', 'dnf', or 'zypper'. Auto-detected if omitted.
    .Link
        https://learn.microsoft.com/powershell/module/packagemanagement/install-package
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
                Write-Error 'Install-Package: No supported package manager found (apt-get/dnf/zypper).'
                return
            }
        }

        foreach ($pkg in $Name) {
            if (-not $PSCmdlet.ShouldProcess($pkg, "Install package via $provider")) { continue }

            switch ($provider) {
                'apt' {
                    $result = & sudo apt-get install -y $pkg 2>&1
                    if ($LASTEXITCODE -ne 0) { Write-Error "Install-Package: apt-get install failed for '$pkg': $result" }
                }
                'dnf' {
                    $result = & sudo dnf install -y $pkg 2>&1
                    if ($LASTEXITCODE -ne 0) { Write-Error "Install-Package: dnf install failed for '$pkg': $result" }
                }
                'zypper' {
                    $result = & sudo zypper install -y $pkg 2>&1
                    if ($LASTEXITCODE -ne 0) { Write-Error "Install-Package: zypper install failed for '$pkg': $result" }
                }
            }
        }
    }
}
