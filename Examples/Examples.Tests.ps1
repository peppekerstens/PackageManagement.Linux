#Requires -Modules @{ ModuleName = 'Pester'; ModuleVersion = '5.2.0' }
<#
.Synopsis
    Pester tests for PackageManagement.Linux example scripts and scenarios.
.Description
    Validates that the module's cmdlets behave correctly.
    Linux-only execution tests are guarded with -Skip:(-not $IsLinux).
    Distro-specific tests are guarded by tool availability.
.Notes
    Free to use under GNU v3 Public License (https://choosealicense.com/licenses/gpl-3.0/)
    Author: Peppe Kerstens (NLD)
    Run with: Invoke-Pester .\Examples.Tests.ps1 -Output Detailed
#>

BeforeDiscovery {
    $script:aptAvailable    = [bool](Get-Command apt    -ErrorAction SilentlyContinue)
    $script:dnfAvailable    = [bool](Get-Command dnf    -ErrorAction SilentlyContinue)
    $script:zypperAvailable = [bool](Get-Command zypper -ErrorAction SilentlyContinue)
}

Describe 'Examples: PackageManagement.Linux' {
    BeforeAll {
        $script:examplesPath = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path $PSCommandPath -Parent }
        $script:moduleRoot   = Split-Path $script:examplesPath -Parent
        $script:modulePath   = Join-Path $script:moduleRoot 'PackageManagement.Linux' 'PackageManagement.Linux.psd1'
        if ($IsLinux) {
            Import-Module $script:modulePath -Force -ErrorAction Stop
        }
    }
    AfterAll {
        if ($IsLinux) {
            Remove-Module 'PackageManagement.Linux' -Force -ErrorAction SilentlyContinue
        }
    }

    Context 'Get-Package returns installed packages' -Skip:(-not $IsLinux) {
        It 'returns at least one package' {
            $pkgs = Get-Package
            $pkgs | Should -Not -BeNullOrEmpty
        }
        It 'returned objects have Name property' {
            $pkgs = Get-Package
            $pkgs[0].PSObject.Properties.Name | Should -Contain 'Name'
        }
    }

    Context 'Get-PackageSource returns configured package sources' -Skip:(-not $IsLinux) {
        It 'returns at least one source' {
            $sources = Get-PackageSource
            $sources | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Find-Package searches for a known package (apt)' -Skip:(-not ($IsLinux -and $script:aptAvailable)) {
        It 'Find-Package curl returns results' {
            $results = Find-Package -Name 'curl'
            $results | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Find-Package searches for a known package (dnf)' -Skip:(-not ($IsLinux -and $script:dnfAvailable)) {
        It 'Find-Package curl returns results' {
            $results = Find-Package -Name 'curl'
            $results | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Find-Package searches for a known package (zypper)' -Skip:(-not ($IsLinux -and $script:zypperAvailable)) {
        It 'Find-Package curl returns results' {
            $results = Find-Package -Name 'curl'
            $results | Should -Not -BeNullOrEmpty
        }
    }
}

Describe 'Scenario: Package install/query/remove lifecycle (apt)' -Skip:(-not ($IsLinux -and $script:aptAvailable)) {
    BeforeAll {
        $modulePath = Join-Path (Split-Path $PSScriptRoot -Parent) 'PackageManagement.Linux' 'PackageManagement.Linux.psd1'
        Import-Module $modulePath -Force -ErrorAction Stop
        # 'hello' is a tiny test package available on all Debian/Ubuntu systems
        $script:testPkg = 'hello'
    }
    AfterAll {
        Uninstall-Package -Name $script:testPkg -ErrorAction SilentlyContinue
        Remove-Module 'PackageManagement.Linux' -Force -ErrorAction SilentlyContinue
    }

    It 'Install-Package installs the test package' {
        { Install-Package -Name $script:testPkg -Force } | Should -Not -Throw
    }
    It 'Get-Package finds the installed package' {
        $pkg = Get-Package -Name $script:testPkg
        $pkg | Should -Not -BeNullOrEmpty
        $pkg.Name | Should -Be $script:testPkg
    }
    It 'Uninstall-Package removes the package' {
        { Uninstall-Package -Name $script:testPkg -Force } | Should -Not -Throw
        $pkg = Get-Package -Name $script:testPkg -ErrorAction SilentlyContinue
        $pkg | Should -BeNullOrEmpty
    }
}
