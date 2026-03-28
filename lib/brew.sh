#!/usr/bin/env bash
# Homebrew helper functions for DevOps App Installer

# Check if Homebrew is installed
brew_is_installed() {
    command -v brew &>/dev/null
}

# Install Homebrew if not present
# Returns 0 on success, 1 on failure
brew_ensure() {
    if brew_is_installed; then
        return 0
    fi

    log_info "Homebrew not found. Installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || {
        log_error "Failed to install Homebrew."
        return 1
    }

    # Add Homebrew to PATH (Apple Silicon and Intel)
    if [ -f /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -f /usr/local/bin/brew ]; then
        eval "$(/usr/local/bin/brew shellenv)"
    fi

    log_success "Homebrew installed."
    return 0
}

# Check if a formula is installed
# Usage: brew_formula_installed <formula_name>
brew_formula_installed() {
    local formula="$1"
    brew list --formula "$formula" &>/dev/null
}

# Check if a cask is installed
# Usage: brew_cask_installed <cask_name>
brew_cask_installed() {
    local cask="$1"
    brew list --cask "$cask" &>/dev/null
}

# Check if a formula/cask is outdated
# Returns 0 (true) if outdated, 1 (false) if up to date
# Usage: brew_is_outdated <name> (formula|cask)
brew_is_outdated() {
    local name="$1"
    local type="$2"
    local result

    if [ "$type" = "formula" ]; then
        brew outdated --formula "$name" &>/dev/null && result=0 || result=1
    else
        brew outdated --cask "$name" &>/dev/null && result=0 || result=1
    fi

    # brew outdated exits 0 when package IS outdated, 1 when up to date
    return $result
}

# Install a formula
# Usage: brew_install_formula <formula_name> [tap]
brew_install_formula() {
    local formula="$1"
    local tap="${2:-}"

    if [ -n "$tap" ]; then
        brew tap "$tap" || return 1
    fi

    brew install "$formula"
}

# Install a cask
# Usage: brew_install_cask <cask_name> [tap]
brew_install_cask() {
    local cask="$1"
    local tap="${2:-}"

    if [ -n "$tap" ]; then
        brew tap "$tap" || return 1
    fi

    brew install --cask "$cask"
}

# Upgrade a formula or cask
# Usage: brew_upgrade <name> (formula|cask)
brew_upgrade() {
    local name="$1"
    local type="$2"

    if [ "$type" = "formula" ]; then
        brew upgrade "$name"
    else
        brew upgrade --cask "$name"
    fi
}
