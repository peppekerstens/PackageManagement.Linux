function Find-Package {
    <#
    .Synopsis
        Searches for packages in the repository via the system package manager.
    .Description
        On Debian/Ubuntu systems, wraps 'apt-cache search' to find available packages.
        On RHEL/Fedora systems, wraps 'dnf search'. On openSUSE, wraps 'zypper se'.
        Returns PSCustomObjects with Name, Version, Description, and PackageManagerName.
    .Parameter Name
        The package name or keyword to search for. Required.
    .Parameter ProviderName
        The package provider to use: 'apt', 'dnf', or 'zypper'. Auto-detected if omitted.
    .Link
        https://learn.microsoft.com/powershell/module/packagemanagement/find-package
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Name,

        [Parameter()]
        [ValidateSet('apt', 'dnf', 'zypper')]
        [string]$ProviderName
    )
    process {
        $provider = $ProviderName
        if (-not $provider) {
            if (Get-Command apt-cache -ErrorAction SilentlyContinue) { $provider = 'apt' }
            elseif (Get-Command dnf -ErrorAction SilentlyContinue)   { $provider = 'dnf' }
            elseif (Get-Command zypper -ErrorAction SilentlyContinue){ $provider = 'zypper' }
            else {
                Write-Error 'Find-Package: No supported package manager found (apt-cache/dnf/zypper).'
                return
            }
        }

        switch ($provider) {
            'apt' {
                $raw = & apt-cache search $Name 2>&1
                if ($LASTEXITCODE -ne 0) { Write-Error "Find-Package: apt-cache search failed: $raw"; return }
                foreach ($line in $raw) {
                    if ($line -match '^([^\s]+) - (.+)$') {
                        [PSCustomObject]@{
                            Name               = $Matches[1]
                            Version            = 'available'
                            Description        = $Matches[2]
                            PackageManagerName = 'apt'
                        }
                    }
                }
            }
            'dnf' {
                $raw = & dnf search $Name 2>&1
                if ($LASTEXITCODE -ne 0) { Write-Error "Find-Package: dnf search failed: $raw"; return }
                foreach ($line in $raw) {
                    if ($line -match '^([^\s.]+)\.[^\s]+ : (.+)$') {
                        [PSCustomObject]@{
                            Name               = $Matches[1]
                            Version            = 'available'
                            Description        = $Matches[2]
                            PackageManagerName = 'dnf'
                        }
                    }
                }
            }
            'zypper' {
                $raw = & zypper --non-interactive se $Name 2>&1
                if ($LASTEXITCODE -ne 0) { Write-Error "Find-Package: zypper se failed: $raw"; return }
                foreach ($line in ($raw | Select-Object -Skip 4)) {
                    if ($line -match '^\s*[i+]?\s*\|') {
                        $cols = $line -split '\|'
                        if ($cols.Count -lt 4) { continue }
                        [PSCustomObject]@{
                            Name               = $cols[1].Trim()
                            Version            = $cols[3].Trim()
                            Description        = $cols[4].Trim()
                            PackageManagerName = 'zypper'
                        }
                    }
                }
            }
        }
    }
}
