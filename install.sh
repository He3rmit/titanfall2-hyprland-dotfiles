#!/bin/bash

# usage: ./install.sh [laptop|desktop]
TARGET=$1

# 1. Safety Check
if [[ -z "$TARGET" ]]; then
    echo "❌ Error: You must specify a target."
    echo "Usage: ./install.sh laptop  OR  ./install.sh desktop"
    exit 1
fi

echo "🚧 Deploying Titanfall Config for: $TARGET"

# 2. Link User Home Files (.zshrc)
# Links ~/dotfiles/home/.zshrc -> ~/.zshrc
stow -v -R -t ~ home

# 3. Link Core Configs (Theming, Scripts, Kitty, Starship)
# Links ~/dotfiles/core/* -> ~/.config/*
stow -v -R -t ~/.config core

# 4. Link Base Hyprland Config
# Links ~/dotfiles/hyprland/* -> ~/.config/hypr/*
stow -v -R -t ~/.config/hypr hyprland

# 5. The "Switch" Logic (Hardware Specifics)
# This forces the link to point to the correct file for this machine
echo "🔗 Linking host-specific configs..."

# Hyprland Host Config
ln -sf "$HOME/dotfiles/hosts/$TARGET/hypr-host.conf" "$HOME/.config/hypr/host.conf"

# Waybar Host Config
ln -sf "$HOME/dotfiles/hosts/$TARGET/waybar/config.jsonc" "$HOME/.config/waybar/config.jsonc"

# Kitty Host Config  <-- ADD THIS LINE
ln -sf "$HOME/dotfiles/hosts/$TARGET/kitty-host.conf" "$HOME/.config/kitty/host.conf"

echo "✅ Configuration applied for $TARGET."

# 6. Reload System
if pgrep Hyprland > /dev/null; then
    echo "🔄 Reloading Hyprland..."
    hyprctl reload
    killall waybar
    waybar &
fi