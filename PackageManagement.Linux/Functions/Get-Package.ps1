function Get-Package {
    <#
    .Synopsis
        Gets a list of installed packages on Linux via the system package manager.
    .Description
        On Debian/Ubuntu systems, wraps 'dpkg-query -W' to list installed packages.
        On RHEL/Fedora systems, wraps 'rpm -qa'. On openSUSE, wraps 'zypper se --installed-only'.
        Returns PSCustomObjects with Name, Version, Source, and PackageManagerName properties.
    .Parameter Name
        Filter packages by name. Supports wildcards. Defaults to '*' (all packages).
    .Parameter ProviderName
        The package provider to query: 'apt', 'rpm', or 'zypper'. Auto-detected if omitted.
    .Link
        https://learn.microsoft.com/powershell/module/packagemanagement/get-package
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Position = 0)]
        [string]$Name = '*',

        [Parameter()]
        [ValidateSet('apt', 'rpm', 'zypper')]
        [string]$ProviderName
    )
    process {
        $provider = $ProviderName
        if (-not $provider) {
            if (Get-Command dpkg-query -ErrorAction SilentlyContinue) { $provider = 'apt' }
            elseif (Get-Command rpm -ErrorAction SilentlyContinue)    { $provider = 'rpm' }
            elseif (Get-Command zypper -ErrorAction SilentlyContinue) { $provider = 'zypper' }
            else {
                Write-Error 'Get-Package: No supported package manager found (dpkg-query/rpm/zypper).'
                return
            }
        }

        switch ($provider) {
            'apt' {
                $raw = & dpkg-query -W -f '${Package}\t${Version}\t${Status}\n' 2>&1
                if ($LASTEXITCODE -ne 0) { Write-Error "Get-Package: dpkg-query failed: $raw"; return }
                foreach ($line in $raw) {
                    $parts = $line -split '\t'
                    if ($parts.Count -lt 3) { continue }
                    if ($parts[2] -notmatch 'installed') { continue }
                    $pkgName = $parts[0]
                    if ($Name -ne '*' -and $pkgName -notlike $Name) { continue }
                    [PSCustomObject]@{
                        Name               = $pkgName
                        Version            = $parts[1]
                        Source             = 'apt'
                        PackageManagerName = 'apt'
                        Status             = 'Installed'
                    }
                }
            }
            'rpm' {
                $raw = & rpm -qa --queryformat '%{NAME}\t%{VERSION}-%{RELEASE}\n' 2>&1
                if ($LASTEXITCODE -ne 0) { Write-Error "Get-Package: rpm failed: $raw"; return }
                foreach ($line in $raw) {
                    $parts = $line -split '\t'
                    if ($parts.Count -lt 2) { continue }
                    $pkgName = $parts[0]
                    if ($Name -ne '*' -and $pkgName -notlike $Name) { continue }
                    [PSCustomObject]@{
                        Name               = $pkgName
                        Version            = $parts[1]
                        Source             = 'rpm'
                        PackageManagerName = 'rpm'
                        Status             = 'Installed'
                    }
                }
            }
            'zypper' {
                $raw = & zypper --non-interactive se --installed-only 2>&1
                if ($LASTEXITCODE -ne 0) { Write-Error "Get-Package: zypper failed: $raw"; return }
                # Skip header lines (start with 'S |' or '---')
                foreach ($line in ($raw | Select-Object -Skip 4)) {
                    if ($line -match '^\s*i') {
                        $cols = $line -split '\|'
                        if ($cols.Count -lt 4) { continue }
                        $pkgName = $cols[1].Trim()
                        if ($Name -ne '*' -and $pkgName -notlike $Name) { continue }
                        [PSCustomObject]@{
                            Name               = $pkgName
                            Version            = $cols[3].Trim()
                            Source             = 'zypper'
                            PackageManagerName = 'zypper'
                            Status             = 'Installed'
                        }
                    }
                }
            }
        }
    }
}
