# DevOps App Installer (Windows)
# Installs, upgrades, or skips DevOps applications using Winget.
# App list is loaded from an extensible YAML registry.

param(
    [string]$Config = "",
    [string]$App = "",
    [switch]$DryRun,
    [switch]$Help
)

$ErrorActionPreference = "Stop"
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$DEFAULT_REGISTRY = Join-Path $SCRIPT_DIR "apps.yaml"

# Counters
$Script:Installed = 0
$Script:Upgraded = 0
$Script:Skipped = 0
$Script:Failed = 0
$Script:FailedList = ""

# Parsed app entries
$Script:AppNames = @()
$Script:AppWingetIds = @()

# ─── Help ───────────────────────────────────────────────────────────
if ($Help) {
    Write-Host @"
Usage: $(Split-Path -Leaf $MyInvocation.MyCommand.Path) [OPTIONS] [APP_NAME]

Options:
  -Config FILE   Path to custom YAML registry (default: apps.yaml)
  -App NAME      Install only a specific app by name
  -DryRun        Show what would be done without executing
  -Help          Show this help message

Examples:
  .\install.ps1                       Install all apps from default registry
  .\install.ps1 -App git              Install only git
  .\install.ps1 -Config my-apps.yaml  Use a custom registry file
  .\install.ps1 -DryRun               Preview actions without executing
"@
    exit 0
}

# ─── Load libraries ─────────────────────────────────────────────────
. (Join-Path $SCRIPT_DIR "lib\log.ps1")
. (Join-Path $SCRIPT_DIR "lib\winget.ps1")

# ─── Parse YAML registry ────────────────────────────────────────────
function Parse-Registry {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        Write-LogError "Registry file not found: $Path"
        exit 1
    }

    $Script:AppNames = @()
    $Script:AppWingetIds = @()

    $inApps = $false
    $currentName = ""
    $currentWinget = ""
    $currentPlatforms = ""

    $lines = Get-Content $Path
    foreach ($line in $lines) {
        # Strip comments
        $commentIdx = $line.IndexOf('#')
        if ($commentIdx -ge 0) {
            $line = $line.Substring(0, $commentIdx)
        }
        $line = $line.Trim()
        if ([string]::IsNullOrWhiteSpace($line)) { continue }

        if ($line -match "^apps:") {
            $inApps = $true
            continue
        }

        if (-not $inApps) { continue }

        if ($line -match "^-\s+name:\s*(.+)") {
            # Flush previous entry
            if ($currentName) {
                Add-Entry $currentName $currentWinget $currentPlatforms
            }
            $currentName = $Matches[1].Trim()
            $currentWinget = ""
            $currentPlatforms = ""
        }
        elseif ($line -match "^winget:\s*(.+)") {
            $currentWinget = $Matches[1].Trim()
        }
        elseif ($line -match "^platforms:\s*\[(.+)\]") {
            $currentPlatforms = $Matches[1].Trim()
        }
        elseif ($line -match "^[^-\s]") {
            # No longer indented — end of apps list
            $inApps = $false
        }
    }

    # Flush last entry
    if ($currentName) {
        Add-Entry $currentName $currentWinget $currentPlatforms
    }
}

function Add-Entry {
    param([string]$Name, [string]$WingetId, [string]$Platforms)

    # Platform filter: skip if platforms is set and doesn't include windows
    if ($Platforms) {
        $platformList = $Platforms -split "," | ForEach-Object { $_.Trim() }
        if ($platformList -notcontains "windows") {
            return
        }
    }

    # Skip apps without a winget ID
    if (-not $WingetId) { return }

    $Script:AppNames += $Name
    $Script:AppWingetIds += $WingetId
}

# ─── Process a single app ───────────────────────────────────────────
function Process-App {
    param([int]$Index)

    $name = $Script:AppNames[$Index]
    $wingetId = $Script:AppWingetIds[$Index]

    # Filter check
    if ($App -and $App -ne $wingetId -and $App -ne $name) {
        return
    }

    Write-LogInfo "Processing $name ($wingetId)..."

    $isInstalled = Test-WingetPackageInstalled $wingetId

    if ($DryRun) {
        if ($isInstalled) {
            Write-LogDryRun "skip $wingetId (already installed)"
            $Script:Skipped++
        } else {
            Write-LogDryRun "install $wingetId"
            $Script:Installed++
        }
        return
    }

    # Live mode
    if ($isInstalled) {
        Write-LogSuccess "$name is installed. Skipping."
        $Script:Skipped++
    } else {
        Write-LogInfo "Installing $name..."
        $result = Install-WingetPackage $wingetId
        if ($result) {
            Write-LogSuccess "$name installed."
            $Script:Installed++
        } else {
            Write-LogError "$name install failed."
            $Script:Failed++
            $Script:FailedList += "${name}:Install failed`n"
        }
    }
}

# ─── Main ───────────────────────────────────────────────────────────
$registry = if ($Config) { $Config } else { $DEFAULT_REGISTRY }

Write-LogInfo "DevOps App Installer (Windows)"
Write-LogInfo "Registry: $registry"
if ($DryRun) { Write-LogInfo "Mode: DRY RUN" }
Write-Host ""

Parse-Registry $registry

$totalApps = $Script:AppNames.Count
if ($totalApps -eq 0) {
    Write-LogError "No apps found in registry."
    exit 1
}

# Validate filter
if ($App) {
    $found = $false
    for ($i = 0; $i -lt $totalApps; $i++) {
        if ($App -eq $Script:AppWingetIds[$i] -or $App -eq $Script:AppNames[$i]) {
            $found = $true
            break
        }
    }
    if (-not $found) {
        Write-LogError "App '$App' not found in registry."
        Write-Host ""
        Write-Host "Available apps:"
        for ($i = 0; $i -lt $Script:AppNames.Count; $i++) {
            Write-Host "  - $($Script:AppNames[$i]) ($($Script:AppWingetIds[$i]))"
        }
        exit 1
    }
}

# Ensure winget (skip in dry-run)
if (-not $DryRun) {
    if (-not (Assert-Winget)) { exit 1 }
}

# Process each app
for ($i = 0; $i -lt $totalApps; $i++) {
    Process-App $i
}

Print-Summary -Installed $Script:Installed -Upgraded $Script:Upgraded -Skipped $Script:Skipped -Failed $Script:Failed -FailedList $Script:FailedList

if ($Script:Failed -gt 0) { exit 1 }
