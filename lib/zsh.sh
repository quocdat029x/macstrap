#!/usr/bin/env bash
# Zsh setup helper functions for the Divine Combo
# Oh My Zsh + autosuggestions + syntax-highlighting + Starship

ZSHRC="$HOME/.zshrc"
OMZ_DIR="$HOME/.oh-my-zsh"
OMZ_CUSTOM_PLUGINS="$OMZ_DIR/custom/plugins"

# ─── Default shell ──────────────────────────────────────────────────
zsh_is_default_shell() {
    [ "$SHELL" = "/bin/zsh" ] || [ "$SHELL" = "/usr/bin/zsh" ]
}

zsh_set_default_shell() {
    if zsh_is_default_shell; then
        log_success "Zsh is already the default shell."
        return 0
    fi

    log_info "Setting Zsh as default shell..."
    chsh -s /bin/zsh
    log_success "Default shell set to Zsh."
}

# ─── Oh My Zsh ──────────────────────────────────────────────────────
omz_is_installed() {
    [ -d "$OMZ_DIR" ]
}

omz_install() {
    if omz_is_installed; then
        log_success "Oh My Zsh is already installed."
        return 0
    fi

    # Backup existing .zshrc
    if [ -f "$ZSHRC" ]; then
        local backup="${ZSHRC}.backup.$(date +%s)"
        cp "$ZSHRC" "$backup"
        log_info "Backed up existing .zshrc to $backup"
    fi

    log_info "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

    if omz_is_installed; then
        log_success "Oh My Zsh installed."
    else
        log_error "Oh My Zsh installation failed."
        return 1
    fi
}

# ─── Plugins ────────────────────────────────────────────────────────
omz_plugin_installed() {
    local plugin="$1"
    [ -d "$OMZ_CUSTOM_PLUGINS/$plugin" ]
}

omz_plugin_install() {
    local plugin="$1"
    local repo="$2"

    if omz_plugin_installed "$plugin"; then
        log_success "Plugin '$plugin' is already installed."
        return 0
    fi

    log_info "Installing plugin '$plugin'..."
    git clone --depth=1 "$repo" "$OMZ_CUSTOM_PLUGINS/$plugin" 2>/dev/null

    if omz_plugin_installed "$plugin"; then
        log_success "Plugin '$plugin' installed."
    else
        log_error "Failed to install plugin '$plugin'."
        return 1
    fi
}

# Add a plugin to the plugins=() array in .zshrc
omz_plugin_enable() {
    local plugin="$1"

    # Check if already enabled
    if grep -q "^plugins=" "$ZSHRC" 2>/dev/null; then
        if grep -q "^plugins=.*${plugin}" "$ZSHRC" 2>/dev/null; then
            log_success "Plugin '$plugin' is already enabled."
            return 0
        fi

        # Append to existing plugins line
        sed -i '' "s/^plugins=(/plugins=(${plugin} /" "$ZSHRC"
        log_success "Plugin '$plugin' enabled in .zshrc."
    else
        # No plugins line found — add one
        echo "" >> "$ZSHRC"
        echo "plugins=(${plugin})" >> "$ZSHRC"
        log_success "Plugin '$plugin' enabled in .zshrc."
    fi
}

# ─── Starship ───────────────────────────────────────────────────────
starship_is_installed() {
    command -v starship &>/dev/null
}

starship_install() {
    if starship_is_installed; then
        log_success "Starship is already installed."
        return 0
    fi

    log_info "Installing Starship via Homebrew..."
    brew_ensure || return 1
    brew install starship

    if starship_is_installed; then
        log_success "Starship installed."
    else
        log_error "Starship installation failed."
        return 1
    fi
}

starship_configure() {
    # Add starship init to .zshrc if not already there
    if grep -q "starship init zsh" "$ZSHRC" 2>/dev/null; then
        log_success "Starship is already configured in .zshrc."
        return 0
    fi

    echo "" >> "$ZSHRC"
    echo "# Starship prompt" >> "$ZSHRC"
    echo 'eval "$(starship init zsh)"' >> "$ZSHRC"
    log_success "Starship configured in .zshrc."
}

# ─── Theme ──────────────────────────────────────────────────────────
# Set ZSH_THEME to empty so Starship handles the prompt
zsh_disable_omz_theme() {
    if [ ! -f "$ZSHRC" ]; then
        return 0
    fi

    if grep -q "^ZSH_THEME=\"\"" "$ZSHRC" 2>/dev/null; then
        return 0
    fi

    sed -i '' 's/^ZSH_THEME=.*/ZSH_THEME=""/' "$ZSHRC"
    log_info "Disabled Oh My Zsh theme (Starship will handle the prompt)."
}

# ─── Starship config ───────────────────────────────────────────────
starship_install_config() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local config_source="$script_dir/../config/starship.toml"
    local config_target="$HOME/.config/starship.toml"

    if [ ! -f "$config_source" ]; then
        log_warn "No starship.toml found at $config_source — skipping config deployment."
        return 0
    fi

    if [ -f "$config_target" ]; then
        log_success "Starship config already exists at $config_target."
        return 0
    fi

    mkdir -p "$(dirname "$config_target")"
    cp "$config_source" "$config_target"
    log_success "Starship config deployed to $config_target."
}
