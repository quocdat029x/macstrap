# Oh My Posh setup helper functions (Windows)
# Installs Oh My Posh and configures PowerShell profile

$PSProfile = $PROFILE

# ─── Oh My Posh ─────────────────────────────────────────────────────
function Test-OhMyPoshInstalled {
    try {
        $null = Get-Command oh-my-posh -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

function Install-OhMyPoshPackage {
    if (Test-OhMyPoshInstalled) {
        Write-LogSuccess "Oh My Posh is already installed."
        return $true
    }

    Write-LogInfo "Installing Oh My Posh via winget..."
    $result = Install-WingetPackage "JanDeDobbeleer.OhMyPosh"

    if (Test-OhMyPoshInstalled) {
        Write-LogSuccess "Oh My Posh installed."
        return $true
    } else {
        Write-LogError "Oh My Posh installation failed."
        return $false
    }
}

# ─── Config ─────────────────────────────────────────────────────────
function Deploy-OhMyPoshConfig {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
    $configSource = Join-Path (Split-Path -Parent $scriptDir) "config\oh-my-posh.toml"
    $configTarget = Join-Path $env:LOCALAPPDATA "oh-my-posh\oh-my-posh.toml"

    if (-not (Test-Path $configSource)) {
        Write-LogWarn "No oh-my-posh.toml found at $configSource - skipping config deployment."
        return
    }

    if (Test-Path $configTarget) {
        Write-LogSuccess "Oh My Posh config already exists at $configTarget."
        return
    }

    $targetDir = Split-Path -Parent $configTarget
    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }

    Copy-Item $configSource $configTarget
    Write-LogSuccess "Oh My Posh config deployed to $configTarget."
}

# ─── Profile ────────────────────────────────────────────────────────
function Add-OhMyPoshToProfile {
    $configPath = Join-Path $env:LOCALAPPDATA "oh-my-posh\oh-my-posh.toml"
    $initLine = "oh-my-posh init pwsh --config `"$configPath`" | Invoke-Expression"

    if (-not (Test-Path $PSProfile)) {
        $profileDir = Split-Path -Parent $PSProfile
        if (-not (Test-Path $profileDir)) {
            New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
        }
        Set-Content -Path $PSProfile -Value ""
    }

    $profileContent = Get-Content $PSProfile -Raw -ErrorAction SilentlyContinue
    if ($profileContent -match [regex]::Escape("oh-my-posh init pwsh")) {
        Write-LogSuccess "Oh My Posh is already configured in PowerShell profile."
        return
    }

    Add-Content -Path $PSProfile -Value ""
    Add-Content -Path $PSProfile -Value "# Oh My Posh prompt"
    Add-Content -Path $PSProfile -Value $initLine
    Write-LogSuccess "Oh My Posh configured in PowerShell profile."
}
