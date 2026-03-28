#!/usr/bin/env bash
# Logging utilities for DevOps App Installer
# Provides colored output and summary table printing.

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

log_info() {
    printf "${BLUE}[INFO]${NC}  %s\n" "$1"
}

log_success() {
    printf "${GREEN}[OK]${NC}    %s\n" "$1"
}

log_warn() {
    printf "${YELLOW}[WARN]${NC}  %s\n" "$1"
}

log_error() {
    printf "${RED}[ERROR]${NC} %s\n" "$1"
}

log_dryrun() {
    printf "${BLUE}[DRY]${NC}   Would %s\n" "$1"
}

# Print a summary table of results
# Usage: print_summary <installed_count> <upgraded_count> <skipped_count> <failed_count> <failed_list>
# failed_list is a newline-separated string of "app_name: error_message"
print_summary() {
    local installed=$1
    local upgraded=$2
    local skipped=$3
    local failed=$4
    local failed_list="$5"
    local total=$((installed + upgraded + skipped + failed))

    printf "\n"
    printf "${BOLD}━━━ Installation Summary ━━━${NC}\n"
    printf "  Total:    %d\n" "$total"
    printf "  ${GREEN}Installed: %d${NC}\n" "$installed"
    printf "  ${BLUE}Upgraded:  %d${NC}\n" "$upgraded"
    printf "  Skipped:   %d\n" "$skipped"
    printf "  ${RED}Failed:    %d${NC}\n" "$failed"

    if [ "$failed" -gt 0 ] && [ -n "$failed_list" ]; then
        printf "\n${RED}Failed apps:${NC}\n"
        printf '%b\n' "$failed_list" | while IFS=':' read -r app msg; do
            [ -n "$app" ] && printf "  - %s: %s\n" "$app" "$msg"
        done
    fi

    printf "\n"
}
