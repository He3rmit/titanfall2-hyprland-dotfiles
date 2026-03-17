#!/bin/bash
# ==============================================================================
# MODULE: 01-stow-configs.sh
# Purpose: Dynamically creates target directories and stows dotfiles safely.
# ==============================================================================

source "$INSTALLER_DIR/scripts/utils.sh"

print_step "Stowing configurations..."

# 1. Link Home Files (No --adopt, safer)
print_step ">> Stowing Home Directory Files..."
cd "$DOTFILES_DIR" || exit 1
stow -v -R -t "$HOME" home

# 2. Dynamic Target Creation for Core
# This prevents GNU Stow from "folding" an entire directory if the target 
# doesn't exist, which causes conflicts later. We create every top-level 
# directory found in core/ inside ~/.config first.
print_step ">> Preparing ~/.config for Core Apps..."
find "$DOTFILES_DIR/core" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | while read -r dir; do
    mkdir -p "$HOME/.config/$dir"
done

print_step ">> Stowing Core Configs..."
stow -v -R -t "$HOME/.config" core

# 3. Handle Host-Specific Config Overrides
print_step ">> Applying Host-Specific Overrides for $TARGET..."
safe_link "$DOTFILES_DIR/hosts/$TARGET/.config/swaync/config.json" "$HOME/.config/swaync/config.json"

# 4. Link Hyprland Environment
print_step ">> Stowing Hyprland Environment..."
stow -v -R -t "$HOME/.config/hypr" hyprland
safe_link "$DOTFILES_DIR/hosts/$TARGET/hypr-host.conf" "$HOME/.config/hypr/host.conf"
safe_link "$DOTFILES_DIR/hosts/$TARGET/kitty-host.conf" "$HOME/.config/kitty/host.conf"

# 5. Waybar Deployment
print_step ">> Initializing Waybar Protocol..."
check_fonts
safe_link "$DOTFILES_DIR/hosts/$TARGET/waybar/config.jsonc" "$HOME/.config/waybar/config.jsonc"

# Fix battery script permissions specifically
chmod +x "$DOTFILES_DIR/core/waybar/scripts/"*.sh

# 6. Live Interface Reload
if pgrep Hyprland > /dev/null; then
    print_step ">> Reloading Hyprland interface elements..."
    hyprctl reload &> /dev/null
    
    # Force Kill & Restart Waybar
    pkill waybar || true
    waybar -c "$HOME/.config/waybar/config.jsonc" -s "$HOME/.config/waybar/style.css" &> /dev/null &
    
    # Reload SwayNC
    if command -v swaync-client &> /dev/null; then
        swaync-client -rs &> /dev/null
    fi
fi

print_success "Configs Stowed Successfully."
