#!/usr/bin/env bash
# Zsh Divine Combo Setup
# Oh My Zsh + zsh-autosuggestions + zsh-syntax-highlighting + Starship Prompt
# Idempotent — safe to run multiple times.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

DRY_RUN=false

# ─── Parse arguments ────────────────────────────────────────────────
usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Set up the Zsh Divine Combo:
  Oh My Zsh + autosuggestions + syntax-highlighting + Starship Prompt

Options:
  --dry-run    Show what would be done without executing
  -h, --help   Show this help message
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run) DRY_RUN=true; shift ;;
        -h|--help) usage ;;
        *) echo "Unknown option: $1"; usage ;;
    esac
done

# ─── Load libraries ─────────────────────────────────────────────────
source "$SCRIPT_DIR/lib/log.sh"
source "$SCRIPT_DIR/lib/brew.sh"
source "$SCRIPT_DIR/lib/zsh.sh"

# ─── Counters ───────────────────────────────────────────────────────
INSTALLED=0
SKIPPED=0
FAILED=0
FAILED_LIST=""

# ─── Steps ──────────────────────────────────────────────────────────
step_ensure_zsh() {
    if zsh_is_default_shell; then
        log_success "Zsh is the default shell."
        SKIPPED=$((SKIPPED + 1))
    elif [ "$DRY_RUN" = true ]; then
        log_dryrun "set zsh as default shell"
        INSTALLED=$((INSTALLED + 1))
    else
        zsh_set_default_shell
        INSTALLED=$((INSTALLED + 1))
    fi
}

step_install_omz() {
    if omz_is_installed; then
        log_success "Oh My Zsh is installed."
        SKIPPED=$((SKIPPED + 1))
    elif [ "$DRY_RUN" = true ]; then
        log_dryrun "install Oh My Zsh"
        INSTALLED=$((INSTALLED + 1))
    else
        omz_install || { FAILED=$((FAILED + 1)); FAILED_LIST="${FAILED_LIST}Oh My Zsh:Install failed\n"; return; }
        INSTALLED=$((INSTALLED + 1))
    fi
}

step_install_plugin() {
    local plugin="$1"
    local repo="$2"

    if omz_plugin_installed "$plugin"; then
        log_success "Plugin '$plugin' installed."
        SKIPPED=$((SKIPPED + 1))
    elif [ "$DRY_RUN" = true ]; then
        log_dryrun "install plugin '$plugin'"
        INSTALLED=$((INSTALLED + 1))
    else
        omz_plugin_install "$plugin" "$repo" || { FAILED=$((FAILED + 1)); FAILED_LIST="${FAILED_LIST}${plugin}:Install failed\n"; return; }
        INSTALLED=$((INSTALLED + 1))
    fi
}

step_enable_plugin() {
    local plugin="$1"

    if [ "$DRY_RUN" = true ]; then
        log_dryrun "enable plugin '$plugin' in .zshrc"
        return
    fi
    omz_plugin_enable "$plugin"
}

step_install_starship() {
    if starship_is_installed; then
        log_success "Starship is installed."
        SKIPPED=$((SKIPPED + 1))
    elif [ "$DRY_RUN" = true ]; then
        log_dryrun "install Starship via Homebrew"
        INSTALLED=$((INSTALLED + 1))
    else
        starship_install || { FAILED=$((FAILED + 1)); FAILED_LIST="${FAILED_LIST}Starship:Install failed\n"; return; }
        INSTALLED=$((INSTALLED + 1))
    fi
}

step_configure_starship() {
    if [ "$DRY_RUN" = true ]; then
        log_dryrun "configure Starship in .zshrc"
        return
    fi
    zsh_disable_omz_theme
    starship_configure
    starship_install_config
}

# ─── Main ───────────────────────────────────────────────────────────
main() {
    log_info "Zsh Divine Combo Setup"
    log_info "Oh My Zsh + autosuggestions + syntax-highlighting + Starship"
    [ "$DRY_RUN" = true ] && log_info "Mode: DRY RUN"
    printf "\n"

    # 1. Ensure zsh is default shell
    step_ensure_zsh

    # 2. Install Oh My Zsh
    step_install_omz

    # 3. Install & enable plugins
    step_install_plugin "zsh-autosuggestions" "https://github.com/zsh-users/zsh-autosuggestions"
    step_enable_plugin "zsh-autosuggestions"

    step_install_plugin "zsh-syntax-highlighting" "https://github.com/zsh-users/zsh-syntax-highlighting"
    step_enable_plugin "zsh-syntax-highlighting"

    # 4. Install & configure Starship
    step_install_starship
    step_configure_starship

    # Summary
    print_summary "$INSTALLED" "0" "$SKIPPED" "$FAILED" "$FAILED_LIST"

    if [ "$DRY_RUN" = false ] && [ "$FAILED" -eq 0 ]; then
        printf "${GREEN}Restart your terminal or run: source ~/.zshrc${NC}\n"
    fi

    if [ "$FAILED" -gt 0 ]; then
        exit 1
    fi
}

main
