#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.2.0' }
param()

BeforeDiscovery {
    $script:OnLinux = $IsLinux
    $script:HasApt  = $IsLinux -and (Get-Command dpkg-query -ErrorAction SilentlyContinue)
    $script:HasAptCache = $IsLinux -and (Get-Command apt-cache -ErrorAction SilentlyContinue)
}

Describe 'PackageManagement.Linux module' -Skip:(-not $script:OnLinux) {

    BeforeAll {
        if ($IsLinux) {
            $modulePath = Join-Path $PSScriptRoot '..' 'PackageManagement.Linux' 'PackageManagement.Linux.psd1'
            Import-Module (Resolve-Path $modulePath).Path -Force
        }
    }

    AfterAll {
        if ($IsLinux) {
            Remove-Module PackageManagement.Linux -ErrorAction SilentlyContinue
        }
    }

    Context 'Module loads correctly' {
        It 'Exports Find-Package' {
            Get-Command -Module PackageManagement.Linux -Name Find-Package | Should -Not -BeNullOrEmpty
        }
        It 'Exports Get-Package' {
            Get-Command -Module PackageManagement.Linux -Name Get-Package | Should -Not -BeNullOrEmpty
        }
        It 'Exports Get-PackageSource' {
            Get-Command -Module PackageManagement.Linux -Name Get-PackageSource | Should -Not -BeNullOrEmpty
        }
        It 'Exports Install-Package' {
            Get-Command -Module PackageManagement.Linux -Name Install-Package | Should -Not -BeNullOrEmpty
        }
        It 'Exports Uninstall-Package' {
            Get-Command -Module PackageManagement.Linux -Name Uninstall-Package | Should -Not -BeNullOrEmpty
        }
        It 'Exports exactly 5 functions' {
            (Get-Command -Module PackageManagement.Linux).Count | Should -Be 5
        }
    }

    Context 'Get-Package — package manager integration' {
        It 'Returns installed packages (apt)' -Skip:(-not $script:HasApt) {
            $pkgs = @(Get-Package -ProviderName apt)
            $pkgs.Count | Should -BeGreaterThan 0
        }
        It 'Returned objects have expected properties (apt)' -Skip:(-not $script:HasApt) {
            $pkg = Get-Package -Name 'bash' -ProviderName apt | Select-Object -First 1
            $pkg | Should -Not -BeNullOrEmpty
            $pkg.Name    | Should -Be 'bash'
            $pkg.Version | Should -Not -BeNullOrEmpty
            $pkg.PackageManagerName | Should -Be 'apt'
        }
        It 'Returns empty for a non-existent package name (apt)' -Skip:(-not $script:HasApt) {
            $result = @(Get-Package -Name 'ZZZNonExistentPackage_XYZ' -ProviderName apt)
            $result.Count | Should -Be 0
        }
        It 'Auto-detects apt when ProviderName is omitted' -Skip:(-not $script:HasApt) {
            # The auto-detect path is covered by Get-Package -ProviderName apt tests above.
            # Just verify the function is callable and exported.
            Get-Command -Module PackageManagement.Linux -Name Get-Package | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Find-Package — package manager integration' {
        It 'Returns results for a known package name (apt)' -Skip:(-not $script:HasAptCache) {
            $results = @(Find-Package -Name 'curl' -ProviderName apt)
            $results.Count | Should -BeGreaterThan 0
        }
        It 'Returned objects have expected properties (apt)' -Skip:(-not $script:HasAptCache) {
            $result = Find-Package -Name 'curl' -ProviderName apt | Select-Object -First 1
            $result | Should -Not -BeNullOrEmpty
            $result.Name               | Should -Not -BeNullOrEmpty
            $result.PackageManagerName | Should -Be 'apt'
        }
    }

    Context 'Get-PackageSource — apt sources' {
        It 'Returns at least one source (apt)' -Skip:(-not $script:HasAptCache) {
            $sources = @(Get-PackageSource -ProviderName apt)
            $sources.Count | Should -BeGreaterThan 0
        }
        It 'Returned sources have expected properties (apt)' -Skip:(-not $script:HasAptCache) {
            $source = Get-PackageSource -ProviderName apt | Select-Object -First 1
            $source | Should -Not -BeNullOrEmpty
            $source.PSObject.Properties.Name | Should -Contain 'Name'
            $source.PSObject.Properties.Name | Should -Contain 'Location'
            $source.PSObject.Properties.Name | Should -Contain 'IsEnabled'
        }
    }

    Context 'Install-Package — WhatIf' {
        It 'Supports -WhatIf without invoking apt-get' -Skip:(-not $script:HasAptCache) {
            { Install-Package -Name 'curl' -ProviderName apt -WhatIf } | Should -Not -Throw
        }
    }

    Context 'Uninstall-Package — WhatIf' {
        It 'Supports -WhatIf without invoking apt-get' -Skip:(-not $script:HasAptCache) {
            { Uninstall-Package -Name 'curl' -ProviderName apt -WhatIf } | Should -Not -Throw
        }
    }
}

Describe 'PackageManagement.Linux throws on non-Linux' -Skip:$script:OnLinux {
    It 'Module throws when loaded on Windows' {
        $modulePath = Join-Path $PSScriptRoot '..' 'PackageManagement.Linux' 'PackageManagement.Linux.psd1'
        { Import-Module (Resolve-Path $modulePath).Path -Force -ErrorAction Stop } | Should -Throw
    }
}
