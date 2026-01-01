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
# Instead of stowing the folder (which causes the conflict), 
# we link the specific config.json directly into the folder Stow just made.
echo "🔗 Overriding SwayNC config for $TARGET..."
ln -sf "$DOTFILES_DIR/hosts/$TARGET/.config/swaync/config.json" "$HOME/.config/swaync/config.json"

# 4. Link Hyprland
cd "$DOTFILES_DIR"
stow -v -R -t "$HOME/.config/hypr" hyprland

# 5. Manual Host Links
ln -sf "$DOTFILES_DIR/hosts/$TARGET/hypr-host.conf" "$HOME/.config/hypr/host.conf"
ln -sf "$DOTFILES_DIR/hosts/$TARGET/kitty-host.conf" "$HOME/.config/kitty/host.conf"

echo "✅ Configuration applied for $TARGET."

# 6. Reload
if pgrep Hyprland > /dev/null; then
    hyprctl reload
    killall waybar && waybar &
    swaync-client -rs && echo "✅ PILOT HUD Refreshed."
fi