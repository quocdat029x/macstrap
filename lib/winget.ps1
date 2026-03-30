# Winget helper functions for DevOps App Installer (Windows)

# Check if winget is available
function Test-WingetAvailable {
    try {
        $null = Get-Command winget -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

# Verify winget is installed
function Assert-Winget {
    if (Test-WingetAvailable) {
        return $true
    }
    Write-LogError "winget not found. Install App Installer from the Microsoft Store or update Windows."
    return $false
}

# Check if a winget package is installed
function Test-WingetPackageInstalled {
    param([string]$Id)
    $result = winget list --id $Id --exact --accept-source-agreements 2>$null
    if ($LASTEXITCODE -eq 0 -and $result -match [regex]::Escape($Id)) {
        return $true
    }
    return $false
}

# Install a winget package
function Install-WingetPackage {
    param([string]$Id)
    winget install --id $Id --exact --accept-package-agreements --accept-source-agreements
    return $LASTEXITCODE -eq 0
}

# Upgrade a winget package
function Upgrade-WingetPackage {
    param([string]$Id)
    winget upgrade --id $Id --exact --accept-package-agreements --accept-source-agreements
    return $LASTEXITCODE -eq 0
}
