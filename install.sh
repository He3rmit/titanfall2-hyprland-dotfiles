#!/bin/bash

TARGET=$1
if [[ -z "$TARGET" ]]; then
    echo "❌ Error: Specify laptop or desktop."
    exit 1
fi

DOTFILES_DIR="$HOME/dotfiles"
echo "🚧 Deploying Titanfall Config for: $TARGET"

# 1. Link Home Files
cd "$DOTFILES_DIR"
stow -v -R --adopt -t "$HOME" home

# 2. Link Core Configs (This creates the ~/.config/swaync folder)
stow -v -R -t "$HOME/.config" core

# 3. Handle the Host-Specific Config (The Manual Override)
echo "🔗 Overriding SwayNC config for $TARGET..."
# Note: If this link is broken, check if you need to remove '.config' from the path below too
ln -sf "$DOTFILES_DIR/hosts/$TARGET/.config/swaync/config.json" "$HOME/.config/swaync/config.json"

# 4. Link Hyprland
cd "$DOTFILES_DIR"
stow -v -R -t "$HOME/.config/hypr" hyprland

# 5. Manual Host Links
ln -sf "$DOTFILES_DIR/hosts/$TARGET/hypr-host.conf" "$HOME/.config/hypr/host.conf"
ln -sf "$DOTFILES_DIR/hosts/$TARGET/kitty-host.conf" "$HOME/.config/kitty/host.conf"

# 6. Waybar Deployment (The Pilot Fix)
echo "📶 Deploying Waybar for $TARGET..."

# Ensure the directory exists
mkdir -p "$HOME/.config/waybar"

# FIX: Removed the extra '.config' from the source path
# It now points correctly to: ~/dotfiles/hosts/laptop/waybar/config.jsonc
ln -sf "$DOTFILES_DIR/hosts/$TARGET/waybar/config.jsonc" "$HOME/.config/waybar/config.jsonc"

echo "✅ Configuration applied for $TARGET."

# 7. Reload Systems
if pgrep Hyprland > /dev/null; then
    echo "🔄 Reloading HUD..."
    hyprctl reload
    
    # Force Kill & Restart Waybar with explicit paths to prevent fallback to defaults
    pkill waybar || true
    waybar -c "$HOME/.config/waybar/config.jsonc" -s "$HOME/.config/waybar/style.css" &
    
    swaync-client -rs && echo "✅ PILOT HUD Refreshed."
fi