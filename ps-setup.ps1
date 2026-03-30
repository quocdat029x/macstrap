# PowerShell Oh My Posh Setup (Windows)
# Installs Oh My Posh + deploys config + configures profile
# Idempotent - safe to run multiple times.

param(
    [switch]$DryRun,
    [switch]$Help
)

$ErrorActionPreference = "Stop"
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path

# ─── Help ───────────────────────────────────────────────────────────
if ($Help) {
    Write-Host @"
Usage: $(Split-Path -Leaf $MyInvocation.MyCommand.Path) [OPTIONS]

Set up the PowerShell Divine Combo:
  Oh My Posh prompt with clean minimal theme

Options:
  -DryRun    Show what would be done without executing
  -Help      Show this help message
"@
    exit 0
}

# ─── Load libraries ─────────────────────────────────────────────────
. (Join-Path $SCRIPT_DIR "lib\log.ps1")
. (Join-Path $SCRIPT_DIR "lib\winget.ps1")
. (Join-Path $SCRIPT_DIR "lib\posh.ps1")

# ─── Counters ───────────────────────────────────────────────────────
$Script:Installed = 0
$Script:Skipped = 0
$Script:Failed = 0
$Script:FailedList = ""

# ─── Steps ──────────────────────────────────────────────────────────
function Step-EnsureOhMyPosh {
    if (Test-OhMyPoshInstalled) {
        Write-LogSuccess "Oh My Posh is installed."
        $Script:Skipped++
    } elseif ($DryRun) {
        Write-LogDryRun "install Oh My Posh via winget"
        $Script:Installed++
    } else {
        $result = Install-OhMyPoshPackage
        if ($result) {
            $Script:Installed++
        } else {
            $Script:Failed++
            $Script:FailedList += "Oh My Posh:Install failed`n"
        }
    }
}

function Step-DeployConfig {
    if ($DryRun) {
        Write-LogDryRun "deploy Oh My Posh config"
        return
    }
    Deploy-OhMyPoshConfig
}

function Step-ConfigureProfile {
    if ($DryRun) {
        Write-LogDryRun "configure Oh My Posh in PowerShell profile"
        return
    }
    Add-OhMyPoshToProfile
}

# ─── Main ───────────────────────────────────────────────────────────
Write-LogInfo "PowerShell Oh My Posh Setup"
Write-LogInfo "Oh My Posh + minimal prompt theme"
if ($DryRun) { Write-LogInfo "Mode: DRY RUN" }
Write-Host ""

# 1. Ensure Oh My Posh is installed
Step-EnsureOhMyPosh

# 2. Deploy config
Step-DeployConfig

# 3. Configure profile
Step-ConfigureProfile

# Summary
Print-Summary -Installed $Script:Installed -Upgraded 0 -Skipped $Script:Skipped -Failed $Script:Failed -FailedList $Script:FailedList

if (-not $DryRun -and $Script:Failed -eq 0) {
    Write-Host "$([char]27)[32mRestart your PowerShell or run: . `$PROFILE$([char]27)[0m"
}

if ($Script:Failed -gt 0) { exit 1 }
