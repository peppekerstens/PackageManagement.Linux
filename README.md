# PackageManagement.Linux

[![Pester Tests](https://github.com/peppekerstens/PackageManagement.Linux/actions/workflows/pester.yml/badge.svg)](https://github.com/peppekerstens/PackageManagement.Linux/actions/workflows/pester.yml)

PowerShell 7.x module providing cmdlet parity with the Windows `PackageManagement` module on Linux. Wraps native package managers (`apt`/`dpkg-query`, `rpm`/`dnf`, `zypper`) to deliver a familiar PowerShell experience for package discovery, installation, and removal.

Part of the **Linux PowerShell Cmdlet Parity** project — inspired by Evgenij Smirnov's [2025 European PowerShell Summit session](https://www.youtube.com/watch?v=RlzinWYIjBY) and documented in the blog series at [peppekerstens.github.io](https://peppekerstens.github.io/linux-command-wrapping-part-1/).

---

## What it does

On **Linux**, auto-detects the available package manager (`apt`/`dpkg-query` on Debian/Ubuntu, `rpm`/`dnf` on RHEL/Fedora, `zypper` on openSUSE) and provides PowerShell cmdlets matching the Windows `PackageManagement` module API. All 5 exported cmdlets are fully implemented.

On **Windows**, the module refuses to load — use the built-in `PackageManagement` module.

> **Note:** The built-in `PackageManagement` module ships with PowerShell and exports some of the same cmdlet names. In Pester tests, use `-ProviderName` explicitly to target this module's implementations and avoid ambiguity.

---

## Requirements

- PowerShell 7.2+
- **Linux only** — the module refuses to load on Windows
- One of: `dpkg-query` (Debian/Ubuntu), `rpm` (RHEL/Fedora/Arch), or `zypper` (openSUSE)

---

## Installation

```powershell
# Clone or copy the module folder to a PSModulePath location, then:
Import-Module PackageManagement.Linux
```

---

## Usage

```powershell
# List all installed packages
Get-Package

# Find available packages matching a name
Find-Package -Name 'curl*'

# Install a package (requires root/sudo elevation)
Install-Package -Name 'jq'

# Remove a package
Uninstall-Package -Name 'jq'

# List configured package sources / repositories
Get-PackageSource

# Force a specific provider
Get-Package -ProviderName rpm
```

---

## Cmdlet Status

Legend: ✅ Implemented &nbsp;|&nbsp; ⚠️ Stub

| Cmdlet | Status | Linux tool | Notes |
|---|:---:|---|---|
| `Find-Package` | ✅ | `apt-cache search` / `dnf search` / `zypper se` | `-Name` filter (wildcards); `-ProviderName` to force provider |
| `Get-Package` | ✅ | `dpkg-query -W` / `rpm -qa` / `zypper se --installed-only` | `-Name` filter (wildcards); `-ProviderName` to force provider; Name, Version, Source, PackageManagerName, Status properties |
| `Get-PackageSource` | ✅ | `/etc/apt/sources.list` / `dnf repolist` / `zypper lr` | Lists configured repositories; `-Name` filter; `-ProviderName` to force provider |
| `Install-Package` | ✅ | `apt-get install` / `dnf install` / `zypper install` | Requires root. `-Name` (positional), `-ProviderName` |
| `Uninstall-Package` | ✅ | `apt-get remove` / `dnf remove` / `zypper remove` | Requires root. `-Name` (positional), `-ProviderName` |

---

## Implementation notes

- Provider auto-detection checks for `dpkg-query` first (Debian/Ubuntu), then `rpm` (RHEL/Fedora), then `zypper` (openSUSE). Override with `-ProviderName apt|rpm|zypper`.
- `Get-Package` on `zypper` skips the 4-line table header and matches only `i` (installed) rows.
- `Install-Package` and `Uninstall-Package` run non-interactively (`-y` / `--non-interactive`) and emit the tool's stdout/stderr as verbose output.
- No Crescendo: all implementations are hand-written private helpers; JSON Crescendo files exist as design documentation only.

---

## CI / Testing

Tested across 5 Linux distributions in containers:

| Distro | Image | Package manager |
|---|---|---|
| Ubuntu 24.04 | `ghcr.io/peppekerstens/testinfra:ubuntu-24.04` | apt |
| Debian 12 | `ghcr.io/peppekerstens/testinfra:debian-12` | apt |
| Fedora 40 | `ghcr.io/peppekerstens/testinfra:fedora-40` | rpm/dnf |
| openSUSE Tumbleweed | `ghcr.io/peppekerstens/testinfra:opensuse-tumbleweed` | zypper |
| Arch Linux | `ghcr.io/peppekerstens/testinfra:arch-latest` | pacman (stub) |

Run locally with:

```powershell
# From the repo root
docker compose -f docker-compose.test.yml up --abort-on-container-exit
```

GitHub Actions runs the same matrix on every push — see `.github/workflows/pester.yml`.

---

## Version history

| Version | Notes |
|---|---|
| 0.1.0 | Initial release. All 5 cmdlets implemented: `Find-Package`, `Get-Package`, `Get-PackageSource`, `Install-Package`, `Uninstall-Package`. Multi-distro GHA + docker-compose. |

---

## License

GPL-3.0 — see [LICENSE](LICENSE).
