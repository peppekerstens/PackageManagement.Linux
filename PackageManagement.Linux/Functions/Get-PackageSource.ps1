function Get-PackageSource {
    <#
    .Synopsis
        Gets the list of configured package sources (repositories) on Linux.
    .Description
        On Debian/Ubuntu systems, reads /etc/apt/sources.list and /etc/apt/sources.list.d/*.
        On RHEL/Fedora systems, wraps 'dnf repolist'. On openSUSE, wraps 'zypper repos'.
        Returns PSCustomObjects with Name, Location, ProviderName, and IsEnabled properties.
    .Parameter Name
        Filter by source name. Defaults to '*' (all sources).
    .Parameter ProviderName
        The package provider: 'apt', 'dnf', or 'zypper'. Auto-detected if omitted.
    .Link
        https://learn.microsoft.com/powershell/module/packagemanagement/get-packagesource
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Position = 0)]
        [string]$Name = '*',

        [Parameter()]
        [ValidateSet('apt', 'dnf', 'zypper')]
        [string]$ProviderName
    )
    process {
        $provider = $ProviderName
        if (-not $provider) {
            if (Get-Command apt-cache -ErrorAction SilentlyContinue)  { $provider = 'apt' }
            elseif (Get-Command dnf -ErrorAction SilentlyContinue)    { $provider = 'dnf' }
            elseif (Get-Command zypper -ErrorAction SilentlyContinue) { $provider = 'zypper' }
            else {
                Write-Error 'Get-PackageSource: No supported package manager found (apt-cache/dnf/zypper).'
                return
            }
        }

        switch ($provider) {
            'apt' {
                $sourceFiles = @('/etc/apt/sources.list') +
                    @(Get-ChildItem '/etc/apt/sources.list.d' -Filter '*.list' -ErrorAction SilentlyContinue |
                        Select-Object -ExpandProperty FullName)
                foreach ($file in $sourceFiles) {
                    $lines = Get-Content $file -ErrorAction SilentlyContinue
                    foreach ($line in $lines) {
                        $trimmed = $line.Trim()
                        $enabled = $true
                        if ($trimmed.StartsWith('#')) {
                            $trimmed = $trimmed.TrimStart('#').Trim()
                            $enabled = $false
                        }
                        if ($trimmed -match '^deb\s+(\S+)\s+(\S+)') {
                            $srcName = "$($Matches[2])-$($Matches[1] -replace 'https?://', '' -replace '/', '-')"
                            if ($Name -ne '*' -and $srcName -notlike $Name) { continue }
                            [PSCustomObject]@{
                                Name         = $srcName
                                Location     = $Matches[1]
                                ProviderName = 'apt'
                                IsEnabled    = $enabled
                            }
                        }
                    }
                }
            }
            'dnf' {
                $raw = & dnf repolist all 2>&1
                if ($LASTEXITCODE -ne 0) { Write-Error "Get-PackageSource: dnf repolist failed: $raw"; return }
                foreach ($line in ($raw | Select-Object -Skip 1)) {
                    if ($line -match '^(\S+)\s+(.+?)\s+(enabled|disabled)\s*$') {
                        $repoName = $Matches[1]
                        if ($Name -ne '*' -and $repoName -notlike $Name) { continue }
                        [PSCustomObject]@{
                            Name         = $repoName
                            Location     = $Matches[2].Trim()
                            ProviderName = 'dnf'
                            IsEnabled    = ($Matches[3] -eq 'enabled')
                        }
                    }
                }
            }
            'zypper' {
                $raw = & zypper --non-interactive repos 2>&1
                if ($LASTEXITCODE -ne 0) { Write-Error "Get-PackageSource: zypper repos failed: $raw"; return }
                foreach ($line in ($raw | Select-Object -Skip 4)) {
                    $cols = $line -split '\|'
                    if ($cols.Count -lt 5) { continue }
                    $repoName = $cols[1].Trim()
                    if ($Name -ne '*' -and $repoName -notlike $Name) { continue }
                    [PSCustomObject]@{
                        Name         = $repoName
                        Location     = $cols[4].Trim()
                        ProviderName = 'zypper'
                        IsEnabled    = ($cols[2].Trim() -eq 'Yes')
                    }
                }
            }
        }
    }
}
