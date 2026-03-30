# Logging utilities for DevOps App Installer (Windows)
# Provides colored output and summary table printing.

function Write-LogInfo {
    param([string]$Message)
    Write-Host "[$([char]27)[34mINFO$([char]27)[0m]  $Message"
}

function Write-LogSuccess {
    param([string]$Message)
    Write-Host "[$([char]27)[32mOK$([char]27)[0m]    $Message"
}

function Write-LogWarn {
    param([string]$Message)
    Write-Host "[$([char]27)[33mWARN$([char]27)[0m]  $Message"
}

function Write-LogError {
    param([string]$Message)
    Write-Host "[$([char]27)[31mERROR$([char]27)[0m] $Message"
}

function Write-LogDryRun {
    param([string]$Message)
    Write-Host "[$([char]27)[34mDRY$([char]27)[0m]   Would $Message"
}

# Print a summary table of results
function Print-Summary {
    param(
        [int]$Installed,
        [int]$Upgraded,
        [int]$Skipped,
        [int]$Failed,
        [string]$FailedList
    )

    $total = $Installed + $Upgraded + $Skipped + $Failed

    Write-Host ""
    Write-Host "$([char]27)[1m--- Installation Summary ---$([char]27)[0m"
    Write-Host "  Total:    $total"
    Write-Host "  $([char]27)[32mInstalled: $Installed$([char]27)[0m"
    Write-Host "  $([char]27)[34mUpgraded:  $Upgraded$([char]27)[0m"
    Write-Host "  Skipped:   $Skipped"
    Write-Host "  $([char]27)[31mFailed:    $Failed$([char]27)[0m"

    if ($Failed -gt 0 -and $FailedList) {
        Write-Host ""
        Write-Host "$([char]27)[31mFailed apps:$([char]27)[0m"
        $FailedList -split "`n" | ForEach-Object {
            if ($_ -match "^(.+?):(.+)$") {
                Write-Host "  - $($Matches[1]): $($Matches[2])"
            }
        }
    }

    Write-Host ""
}
