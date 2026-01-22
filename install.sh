#!/bin/bash

# --- PILOT AUTHORIZATION ---
# Ask for the password once and keep the timestamp fresh
echo "Initializing Pilot Authorization..."
sudo -v

# Background loop to update the sudo timestamp every 60 seconds
# It kills itself automatically when the parent script (install.sh) exits
while true; do 
    sudo -n true
    sleep 60
    kill -0 "$$" || exit
done 2>/dev/null &

# --- START DEPLOYMENT ---
# Rest of your script follows here...

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

# 2. Link Core Configs
stow -v -R -t "$HOME/.config" core

# 3. Handle Host-Specific Configs
echo "🔗 Overriding SwayNC config for $TARGET..."
ln -sf "$DOTFILES_DIR/hosts/$TARGET/.config/swaync/config.json" "$HOME/.config/swaync/config.json"

# 4. Link Hyprland
cd "$DOTFILES_DIR"
stow -v -R -t "$HOME/.config/hypr" hyprland
ln -sf "$DOTFILES_DIR/hosts/$TARGET/hypr-host.conf" "$HOME/.config/hypr/host.conf"
ln -sf "$DOTFILES_DIR/hosts/$TARGET/kitty-host.conf" "$HOME/.config/kitty/host.conf"

# 5. Waybar Deployment (Mark 4: Power Scout)
echo "📶 Deploying Waybar for $TARGET..."
mkdir -p "$HOME/.config/waybar"
ln -sf "$DOTFILES_DIR/hosts/$TARGET/waybar/config.jsonc" "$HOME/.config/waybar/config.jsonc"

# CRITICAL: Make the Scout Script Executable
# This fixes the permission error for the battery script
chmod +x "$DOTFILES_DIR/core/waybar/scripts/"*.sh

echo "✅ Configuration applied for $TARGET."

# 6. Reload Systems
if pgrep Hyprland > /dev/null; then
    echo "🔄 Reloading HUD..."
    hyprctl reload
    
    # Force Kill & Restart Waybar
    pkill waybar || true
    waybar -c "$HOME/.config/waybar/config.jsonc" -s "$HOME/.config/waybar/style.css" &
    
    swaync-client -rs 
    echo "✅ PILOT HUD Refreshed."
fi

# 7. SDDM Hatch Protocol (System-Level)
echo "🔓 Engaging SDDM Hatch Protocol..."

THEME_NAME="sddm-astronaut-theme"
THEME_DIR="/usr/share/sddm/themes/$THEME_NAME"

# 1. THE SWITCH: Enable the Theme in the global config
sudo mkdir -p /etc/sddm.conf.d
sudo ln -sf "$DOTFILES_DIR/core/sddm/sddm.conf.d/theme.conf" "/etc/sddm.conf.d/theme.conf"

# 2. THE VIDEO: Deploy to 'Backgrounds' (Modern Standard)
sudo mkdir -p "$THEME_DIR/Backgrounds"
sudo cp -u "$DOTFILES_DIR/core/sddm/astronaut/titan-hatch.mp4" "$THEME_DIR/Backgrounds/titan-hatch.mp4"

# 3. THE HUD: Link User Settings to the sub-theme folder
sudo mkdir -p "$THEME_DIR/Themes"
sudo ln -sf "$DOTFILES_DIR/core/sddm/astronaut/theme.conf.user" "$THEME_DIR/Themes/astronaut.conf.user"

# 4. Permissions: Ensure SDDM user can read the assets
sudo chown -R sddm:sddm "$THEME_DIR/Backgrounds"
sudo chmod 644 "$THEME_DIR/Backgrounds/titan-hatch.mp4"

echo "🏁 Protocol Complete. Welcome back, Pilot."