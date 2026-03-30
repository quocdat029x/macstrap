# macstrap

> Bootstrap your dev machine in one command. macOS (Homebrew) and Windows (Winget) supported. YAML-driven, extensible.

Stop spending hours setting up a new machine. macstrap installs your entire DevOps stack — Git, Docker, Lens, IDEs, and more — with a single command. Add your own apps in YAML. Works on macOS and Windows.

## Prerequisites

### macOS
- **macOS** (Apple Silicon or Intel)
- **Internet connection**
- Homebrew is auto-installed if missing

### Windows
- **Windows 10** (21H1+) or **Windows 11**
- **Internet connection**
- Winget (comes pre-installed with App Installer from Microsoft Store)

## Quick Start

### macOS / Linux

```bash
# Install all apps from the default registry
./install.sh

# Preview what would happen
./install.sh --dry-run

# Install a single app
./install.sh git

# Use a custom registry
./install.sh -c my-apps.yaml
```

### Windows

```powershell
# Install all apps from the default registry
.\install.ps1

# Preview what would happen
.\install.ps1 -DryRun

# Install a single app
.\install.ps1 -App git

# Use a custom registry
.\install.ps1 -Config my-apps.yaml
```

## Shell Setup

### macOS — Zsh + Oh My Zsh + Starship

```bash
./zsh-setup.sh          # Set up Zsh with plugins and Starship prompt
./zsh-setup.sh --dry-run # Preview
```

### Windows — PowerShell + Oh My Posh

```powershell
.\ps-setup.ps1          # Set up Oh My Posh prompt
.\ps-setup.ps1 -DryRun  # Preview
```

## Usage

### macOS / Linux

```
Usage: install.sh [OPTIONS] [APP_NAME]

Options:
  -c, --config FILE   Path to custom YAML registry (default: apps.yaml)
  --dry-run           Show what would be done without executing
  -h, --help          Show this help message
```

### Windows

```
Usage: install.ps1 [OPTIONS]

Options:
  -Config FILE   Path to custom YAML registry (default: apps.yaml)
  -App NAME      Install only a specific app by name
  -DryRun        Show what would be done without executing
  -Help          Show this help message
```

## Default Apps

| App | macOS (Homebrew) | Windows (Winget) |
|-----|------------------|-------------------|
| Git | `git` (formula) | `Git.Git` |
| cURL | `curl` (formula) | `cURL.cURL` |
| jq | `jq` (formula) | `jqlang.jq` |
| yq | `yq` (formula) | `MikeFarah.yq` |
| tree | `tree` (formula) | `tucnak.tree` |
| GitHub CLI | `gh` (formula) | `GitHub.cli` |
| fzf | `fzf` (formula) | `junegunn.fzf` |
| uv | `uv` (formula) | `astral-sh.uv` |
| AWS CLI | `awscli` (formula) | `Amazon.AWSCLI` |
| Azure CLI | `azure-cli` (formula) | `Microsoft.AzureCLI` |
| Go | `go` (formula) | `GoLang.Go` |
| Node.js | `node` (formula) | `OpenJS.NodeJS.LTS` |
| Docker Desktop | `docker` (cask) | `Docker.DockerDesktop` |
| Lens | `lens` (cask) | `Mirantis.Lens` |
| GoLand | `goland` (cask) | `JetBrains.GoLand` |
| WebStorm | `webstorm` (cask) | `JetBrains.WebStorm` |
| Obsidian | `obsidian` (cask) | `Obsidian.Obsidian` |
| VS Code | `visual-studio-code` (cask) | `Microsoft.VisualStudioCode` |
| Postman | `postman` (cask) | `Postman.Postman` |
| LM Studio | `lm-studio` (cask) | `ElementLabs.LMStudio` |
| Wireshark | `wireshark` (cask) | `WiresharkFoundation.Wireshark` |
| Burp Suite | `burp-suite` (cask) | `PortSwigger.BurpSuite.Community` |
| BetterDisplay | `betterdisplay` (cask) | macOS only |
| Synology Drive | `synology-drive` (cask) | macOS only |
| htop | `htop` (formula) | macOS/Linux only |
| tmux | `tmux` (formula) | macOS/Linux only |
| Stern | `stern` (formula) | macOS/Linux only |

## Adding New Apps

Edit `apps.yaml` and add an entry:

```yaml
  - name: Your App
    cask: your-app        # for GUI apps (macOS)
    winget: Publisher.App # for Windows
```

or

```yaml
  - name: Your CLI Tool
    formula: your-tool    # for CLI tools (macOS)
    winget: Publisher.Tool
```

### Platform-specific apps

Use the `platforms` field to restrict an app to certain platforms:

```yaml
  - name: macOS-only App
    cask: some-app
    platforms: [macos]

  - name: Cross-platform Tool
    formula: tool
    winget: Publisher.Tool
    # No platforms field = available everywhere
```

Valid platform values: `macos`, `linux`, `windows`.

## How It Works

1. Detects platform (macOS/Linux uses Homebrew, Windows uses Winget)
2. Reads the YAML registry
3. Filters apps by platform compatibility
4. For each app:
   - **Not installed** → installs it
   - **Installed but outdated** → upgrades it (macOS only; Windows skips installed apps)
   - **Installed and current** → skips it
5. Prints a summary report

## License

MIT
