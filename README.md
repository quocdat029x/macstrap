<div align="center">

# macstrap

**Bootstrap your dev machine in one command.**

Cross-platform, YAML-driven, zero-config DevOps toolkit installer.

macOS (Homebrew) | Windows (Winget)

---

[Features](#features) · [Quick Start](#quick-start) · [App Catalog](#app-catalog) · [Adding Apps](#adding-new-apps) · [How It Works](#how-it-works)

</div>

---

## Features

- **One command, full stack** — Git, Docker, Terraform, IDEs, cloud CLIs, and more
- **Cross-platform** — same `apps.yaml` registry powers both macOS and Windows
- **YAML-driven** — add or remove apps by editing a single file
- **Smart** — installs missing apps, upgrades outdated ones, skips what's current
- **Dry-run mode** — preview every action before it happens
- **Shell setup included** — Zsh + Starship on macOS, PowerShell + Oh My Posh on Windows

## Quick Start

### macOS / Linux

```bash
./install.sh              # Install everything
./install.sh --dry-run    # Preview first
./install.sh git          # Install a single app
./install.sh -c my.yaml   # Custom registry
```

Shell setup:

```bash
./zsh-setup.sh            # Zsh + Oh My Zsh + Starship
```

### Windows

```powershell
.\install.ps1                      # Install everything
.\install.ps1 -DryRun              # Preview first
.\install.ps1 -App git             # Install a single app
.\install.ps1 -Config my.yaml      # Custom registry
```

Shell setup:

```powershell
.\ps-setup.ps1             # Oh My Posh prompt
```

### Prerequisites

| Platform | Requirement |
|----------|-------------|
| macOS | Apple Silicon or Intel, internet connection |
| Windows | Windows 10 (21H1+) or Windows 11, internet connection |
| macOS | Homebrew (auto-installed if missing) |
| Windows | Winget (pre-installed via App Installer) |

## App Catalog

### CLI Essentials

| App | macOS | Windows | Notes |
|-----|-------|---------|-------|
| Git | `git` | `Git.Git` | |
| cURL | `curl` | `cURL.cURL` | |
| jq | `jq` | `jqlang.jq` | |
| yq | `yq` | `MikeFarah.yq` | |
| tree | `tree` | `tucnak.tree` | |
| GitHub CLI | `gh` | `GitHub.cli` | |
| fzf | `fzf` | `junegunn.fzf` | |
| uv | `uv` | `astral-sh.uv` | Python/uvx |
| AWS CLI | `awscli` | `Amazon.AWSCLI` | |
| Azure CLI | `azure-cli` | `Microsoft.AzureCLI` | |
| Pre-commit | `pre-commit` | `pre-commit.pre-commit` | |
| htop | `htop` | — | macOS/Linux only |
| tmux | `tmux` | — | macOS/Linux only |
| Stern | `stern` | — | macOS/Linux only |
| Wget | `wget` | — | macOS/Linux only |

### Dev Tools & IaC

| App | macOS | Windows | Notes |
|-----|-------|---------|-------|
| Go | `go` | `GoLang.Go` | |
| Node.js | `node` | `OpenJS.NodeJS.LTS` | |
| Terraform | `terraform` | `Hashicorp.Terraform` | |
| OpenTofu | `opentofu` | `OpenTofu.OpenTofu` | |

### GUI Apps

| App | macOS | Windows | Notes |
|-----|-------|---------|-------|
| Docker Desktop | `docker` | `Docker.DockerDesktop` | |
| Lens | `lens` | `Mirantis.Lens` | |
| GoLand | `goland` | `JetBrains.GoLand` | |
| WebStorm | `webstorm` | `JetBrains.WebStorm` | |
| VS Code | `visual-studio-code` | `Microsoft.VisualStudioCode` | |
| Obsidian | `obsidian` | `Obsidian.Obsidian` | |
| Postman | `postman` | `Postman.Postman` | |
| LM Studio | `lm-studio` | `ElementLabs.LMStudio` | |
| BetterDisplay | `betterdisplay` | — | macOS only |
| Synology Drive | `synology-drive` | — | macOS only |

### Network & Security

| App | macOS | Windows | Notes |
|-----|-------|---------|-------|
| Wireshark | `wireshark` | `WiresharkFoundation.Wireshark` | |
| Burp Suite | `burp-suite` | `PortSwigger.BurpSuite.Community` | |
| WinBox | `winbox` | `MikroTik.WinBox` | |
| WireGuard | `wireguard-tools` | — | macOS/Linux only |

## Adding New Apps

Edit `apps.yaml` and add an entry:

```yaml
# Cross-platform GUI app
- name: Your App
  cask: your-app          # macOS (Homebrew cask)
  winget: Publisher.App   # Windows (Winget)

# Cross-platform CLI tool
- name: Your Tool
  formula: your-tool      # macOS (Homebrew formula)
  winget: Publisher.Tool  # Windows

# macOS-only app
- name: Mac App
  cask: mac-app
  platforms: [macos]

# Skip Windows, available everywhere else
- name: Linux Tool
  formula: linux-tool
  platforms: [macos, linux]
```

Valid `platforms` values: `macos`, `linux`, `windows`. Omitting `platforms` makes the app available everywhere.

## How It Works

```
┌──────────────────────────────────────────┐
│           macstrap install               │
├──────────────────────────────────────────┤
│  1. Detect platform (macOS / Windows)    │
│  2. Load apps.yaml registry              │
│  3. Filter by platform compatibility     │
│  4. For each app:                        │
│     ├── Not installed  → install         │
│     ├── Outdated       → upgrade         │
│     └── Up to date     → skip            │
│  5. Print summary report                 │
└──────────────────────────────────────────┘
```

## Project Structure

```
macstrap/
├── install.sh              # macOS/Linux installer
├── install.ps1             # Windows installer
├── apps.yaml               # Unified app registry
├── zsh-setup.sh            # macOS shell setup
├── ps-setup.ps1            # Windows shell setup
├── config/
│   ├── starship.toml       # macOS prompt config
│   └── oh-my-posh.toml     # Windows prompt config
└── lib/
    ├── log.sh              # Bash logging
    ├── log.ps1             # PowerShell logging
    ├── brew.sh             # Homebrew helpers
    ├── winget.ps1          # Winget helpers
    ├── zsh.sh              # Zsh/Oh-My-Zsh setup
    └── posh.ps1            # Oh My Posh setup
```

## License

MIT
