#!/usr/bin/env bash
# DevOps App Installer
# Installs, upgrades, or skips DevOps applications using Homebrew.
# App list is loaded from an extensible YAML registry.
# No external dependencies — YAML is parsed with pure bash/awk.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_REGISTRY="$SCRIPT_DIR/apps.yaml"

# Shell flags
DRY_RUN=false
REGISTRY=""
FILTER_APP=""

# Counters
INSTALLED=0
UPGRADED=0
SKIPPED=0
FAILED=0
FAILED_LIST=""

# Parsed app entries (parallel arrays)
APP_NAMES=()
APP_BREW_NAMES=()
APP_TYPES=()      # "formula" or "cask"
APP_TAPS=()

# ─── Parse arguments ────────────────────────────────────────────────
usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS] [APP_NAME]

Options:
  -c, --config FILE   Path to custom YAML registry (default: apps.yaml)
  --dry-run           Show what would be done without executing
  -h, --help          Show this help message

Examples:
  $(basename "$0")                  Install all apps from default registry
  $(basename "$0") git              Install only git
  $(basename "$0") -c my-apps.yaml  Use a custom registry file
  $(basename "$0") --dry-run        Preview actions without executing
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        -c|--config)
            if [ $# -lt 2 ]; then
                echo "Error: -c/--config requires a file path argument" >&2
                exit 1
            fi
            REGISTRY="$2"
            shift 2
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        -h|--help)
            usage
            ;;
        -*)
            echo "Unknown option: $1"
            usage
            ;;
        *)
            FILTER_APP="$1"
            shift
            ;;
    esac
done

REGISTRY="${REGISTRY:-$DEFAULT_REGISTRY}"

# ─── Load libraries ─────────────────────────────────────────────────
source "$SCRIPT_DIR/lib/log.sh"
source "$SCRIPT_DIR/lib/brew.sh"

# ─── Parse YAML registry (pure bash/awk) ────────────────────────────
# Parses a simple YAML structure:
#   apps:
#     - name: X
#       formula: Y    (or cask: Y)
#       tap: Z        (optional)
parse_registry() {
    if [ ! -f "$REGISTRY" ]; then
        log_error "Registry file not found: $REGISTRY"
        exit 1
    fi

    APP_NAMES=()
    APP_BREW_NAMES=()
    APP_TYPES=()
    APP_TAPS=()

    local in_apps=false current_name="" current_formula="" current_cask="" current_tap=""

    while IFS= read -r line; do
        # Strip Windows carriage returns
        line="${line//$'\r'/}"

        # Strip comments
        line="${line%%#*}"

        # Skip empty lines
        [[ -z "${line// /}" ]] && continue

        # Detect start of apps list
        if [[ "$line" =~ ^apps: ]]; then
            in_apps=true
            continue
        fi

        # Only process lines under apps:
        if [ "$in_apps" = true ]; then
            # Detect new list item (  - name: ...)
            if [[ "$line" =~ ^[[:space:]]+-[[:space:]]name:[[:space:]]*(.*) ]]; then
                # Flush previous entry
                if [ -n "$current_name" ]; then
                    flush_entry "$current_name" "$current_formula" "$current_cask" "$current_tap"
                fi
                current_name="${BASH_REMATCH[1]}"
                current_formula=""
                current_cask=""
                current_tap=""
            elif [[ "$line" =~ ^[[:space:]]+formula:[[:space:]]*(.*) ]]; then
                current_formula="${BASH_REMATCH[1]}"
            elif [[ "$line" =~ ^[[:space:]]+cask:[[:space:]]*(.*) ]]; then
                current_cask="${BASH_REMATCH[1]}"
            elif [[ "$line" =~ ^[[:space:]]+tap:[[:space:]]*(.*) ]]; then
                current_tap="${BASH_REMATCH[1]}"
            elif [[ ! "$line" =~ ^[[:space:]] ]]; then
                # No longer indented — end of apps list
                in_apps=false
            fi
        fi
    done < "$REGISTRY"

    # Flush last entry
    if [ -n "$current_name" ]; then
        flush_entry "$current_name" "$current_formula" "$current_cask" "$current_tap"
    fi
}

flush_entry() {
    local name="$1" formula="$2" cask="$3" tap="$4"

    if [ -n "$formula" ]; then
        APP_NAMES+=("$name")
        APP_BREW_NAMES+=("$formula")
        APP_TYPES+=("formula")
        APP_TAPS+=("${tap:-}")
    elif [ -n "$cask" ]; then
        APP_NAMES+=("$name")
        APP_BREW_NAMES+=("$cask")
        APP_TYPES+=("cask")
        APP_TAPS+=("${tap:-}")
    fi
}

# ─── Process a single app ───────────────────────────────────────────
process_app() {
    local idx="$1"
    local name="${APP_NAMES[$idx]}"
    local brew_name="${APP_BREW_NAMES[$idx]}"
    local install_type="${APP_TYPES[$idx]}"
    local tap="${APP_TAPS[$idx]}"

    # Filter check
    if [ -n "$FILTER_APP" ] && [ "$FILTER_APP" != "$brew_name" ] && [ "$FILTER_APP" != "$name" ]; then
        return 1  # filtered out
    fi

    log_info "Processing $name ($brew_name)..."

    # Check installed status
    local is_installed=false
    if brew_is_installed; then
        if [ "$install_type" = "formula" ]; then
            brew_formula_installed "$brew_name" && is_installed=true
        else
            brew_cask_installed "$brew_name" && is_installed=true
        fi
    fi

    # Dry-run mode
    if [ "$DRY_RUN" = true ]; then
        if [ "$is_installed" = true ]; then
            if brew_is_outdated "$brew_name" "$install_type"; then
                log_dryrun "upgrade $brew_name ($install_type)"
                UPGRADED=$((UPGRADED + 1))
            else
                log_dryrun "skip $brew_name (already up to date)"
                SKIPPED=$((SKIPPED + 1))
            fi
        else
            log_dryrun "install $brew_name ($install_type)"
            INSTALLED=$((INSTALLED + 1))
        fi
        return 0
    fi

    # Live mode
    if [ "$is_installed" = true ]; then
        if brew_is_outdated "$brew_name" "$install_type"; then
            log_info "Upgrading $name..."
            if brew_upgrade "$brew_name" "$install_type"; then
                log_success "$name upgraded."
                UPGRADED=$((UPGRADED + 1))
            else
                log_error "$name upgrade failed."
                FAILED=$((FAILED + 1))
                FAILED_LIST="${FAILED_LIST}${name}:Upgrade failed\n"
            fi
        else
            log_success "$name is up to date. Skipping."
            SKIPPED=$((SKIPPED + 1))
        fi
    else
        log_info "Installing $name..."
        local result=0
        if [ "$install_type" = "formula" ]; then
            brew_install_formula "$brew_name" "$tap" || result=$?
        else
            brew_install_cask "$brew_name" "$tap" || result=$?
        fi

        if [ $result -eq 0 ]; then
            log_success "$name installed."
            INSTALLED=$((INSTALLED + 1))
        else
            log_error "$name install failed (exit code $result)."
            FAILED=$((FAILED + 1))
            FAILED_LIST="${FAILED_LIST}${name}:Install failed (exit $result)\n"
        fi
    fi
}

# ─── Main ───────────────────────────────────────────────────────────
main() {
    log_info "DevOps App Installer"
    log_info "Registry: $REGISTRY"
    [ "$DRY_RUN" = true ] && log_info "Mode: DRY RUN"
    printf "\n"

    # Parse registry first (no dependencies needed)
    parse_registry

    local total_apps=${#APP_NAMES[@]}
    if [ "$total_apps" -eq 0 ]; then
        log_error "No apps found in registry."
        exit 1
    fi

    # Validate filter
    if [ -n "$FILTER_APP" ]; then
        local found=false
        for i in $(seq 0 $((total_apps - 1))); do
            if [ "$FILTER_APP" = "${APP_BREW_NAMES[$i]}" ] || [ "$FILTER_APP" = "${APP_NAMES[$i]}" ]; then
                found=true
                break
            fi
        done
        if [ "$found" = false ]; then
            log_error "App '$FILTER_APP' not found in registry."
            printf "\nAvailable apps:\n"
            for i in $(seq 0 $((total_apps - 1))); do
                printf "  - %s (%s)\n" "${APP_NAMES[$i]}" "${APP_BREW_NAMES[$i]}"
            done
            exit 1
        fi
    fi

    # Ensure Homebrew (skip in dry-run)
    if [ "$DRY_RUN" = false ]; then
        brew_ensure || exit 1
    fi

    # Process each app
    for i in $(seq 0 $((total_apps - 1))); do
        process_app "$i" || true
    done

    print_summary "$INSTALLED" "$UPGRADED" "$SKIPPED" "$FAILED" "$FAILED_LIST"

    if [ "$FAILED" -gt 0 ]; then
        exit 1
    fi
}

main
