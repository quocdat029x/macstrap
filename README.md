# macstrap

> Bootstrap your macOS dev machine in one command. Homebrew-powered, YAML-driven, extensible.

Stop spending hours setting up a new Mac. macstrap installs your entire DevOps stack — Git, Docker, Lens, IDEs, and more — with a single command. Add your own apps in YAML.

## Prerequisites

- **macOS** (Apple Silicon or Intel)
- **Internet connection** (Homebrew and apps are downloaded)
- Homebrew is auto-installed if missing

## Quick Start

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

## Usage

```
Usage: install.sh [OPTIONS] [APP_NAME]

Options:
  -c, --config FILE   Path to custom YAML registry (default: apps.yaml)
  --dry-run           Show what would be done without executing
  -h, --help          Show this help message
```

## Default Apps

| App | Type | Homebrew |
|-----|------|----------|
| Git | CLI | `brew install git` |
| Docker Desktop | GUI | `brew install --cask docker` |
| Lens | GUI | `brew install --cask lens` |
| GoLand | GUI | `brew install --cask goland` |
| WebStorm | GUI | `brew install --cask webstorm` |
| Obsidian | GUI | `brew install --cask obsidian` |
| VS Code | GUI | `brew install --cask visual-studio-code` |
| Synology Drive | GUI | `brew install --cask synology-drive` |

## Adding New Apps

Edit `apps.yaml` and add an entry:

```yaml
  - name: Your App
    cask: your-app        # for GUI apps
```

or

```yaml
  - name: Your CLI Tool
    formula: your-tool    # for CLI tools
```

Optional: add a custom tap:

```yaml
  - name: Custom App
    cask: custom-app
    tap: some/tap
```

## How It Works

1. Checks for Homebrew — installs it if missing
2. Reads the YAML registry
3. For each app:
   - **Not installed** → installs it
   - **Installed but outdated** → upgrades it
   - **Installed and current** → skips it
4. Prints a summary report

## License

MIT
