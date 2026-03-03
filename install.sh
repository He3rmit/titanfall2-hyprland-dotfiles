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

# --- PILOT UTILITIES ---

# Safety Protocol: Backup existing files before symlinking
safe_link() {
    local source="$1"
    local target="$2"
    mkdir -p "$(dirname "$target")"

    if [ -L "$target" ]; then
        # It's already a symlink, just replace it
        rm "$target"
    elif [ -e "$target" ]; then
        # It's a real file, back it up
        echo "!!! Existing file detected at $target. Creating backup (.bak) !!!"
        mv "$target" "${target}.bak"
    fi
    ln -s "$source" "$target"
}

# HUD Verification: Check for necessary fonts to avoid "?" icons
check_fonts() {
    local font_name="ShureTechMono Nerd Font"
    if ! fc-list : family | grep -iq "$font_name"; then
        echo "X WARNING: $font_name not found. Workspace icons may show as '?'"
        echo " Hint: Install the font from your dotfiles or AUR."
    else
        echo "✨ Font $font_name verified. HUD icons nominal."
    fi
}

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
# --- ADD THESE LINES ---
echo "📂 Pre-creating config directories to prevent Stow folding..."
mkdir -p "$HOME/.config/waybar"
mkdir -p "$HOME/.config/swaync"
mkdir -p "$HOME/.config/hypr"
mkdir -p "$HOME/.config/fastfetch"
mkdir -p "$HOME/.config/wtf"

# Backup default wtfutil config if it exists so stow doesn't conflict
if [ -f "$HOME/.config/wtf/config.yml" ] && [ ! -L "$HOME/.config/wtf/config.yml" ]; then
    echo "⚠️  Existing file detected at $HOME/.config/wtf/config.yml. Creating backup (.bak)"
    mv "$HOME/.config/wtf/config.yml" "$HOME/.config/wtf/config.yml.bak"
fi
# -----------------------

stow -v -R -t "$HOME/.config" core

# 3. Handle Host-Specific Configs
echo "🔗 Overriding SwayNC config for $TARGET..."
safe_link "$DOTFILES_DIR/hosts/$TARGET/.config/swaync/config.json" "$HOME/.config/swaync/config.json"

# 4. Link Hyprland
cd "$DOTFILES_DIR"
stow -v -R -t "$HOME/.config/hypr" hyprland
safe_link "$DOTFILES_DIR/hosts/$TARGET/hypr-host.conf" "$HOME/.config/hypr/host.conf"
safe_link "$DOTFILES_DIR/hosts/$TARGET/kitty-host.conf" "$HOME/.config/kitty/host.conf"

# 5. Waybar Deployment (Mark 4: Power Scout)
echo "📶 Deploying Waybar for $TARGET..."
check_fonts # Run the font check right before Waybar starts
safe_link "$DOTFILES_DIR/hosts/$TARGET/waybar/config.jsonc" "$HOME/.config/waybar/config.jsonc"

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

# 7. SDDM Cinematic Protocol (System-Level)
echo "🔓 Engaging SDDM Cinematic Protocol..."

THEME_NAME="sddm-astronaut-theme"
THEME_DIR="/usr/share/sddm/themes/$THEME_NAME"

# 1. THE SWITCH: Enable the Theme in the global config
sudo mkdir -p /etc/sddm.conf.d
sudo ln -sf "$DOTFILES_DIR/core/sddm/sddm.conf.d/theme.conf" "/etc/sddm.conf.d/theme.conf"

# 2. THE VIDEO: Deploy to 'Movies' (Standard for this theme)
sudo mkdir -p "$THEME_DIR/Movies"
sudo cp -u "$DOTFILES_DIR/core/sddm/astronaut/Movies/titanfall_intro_cinematic.mp4" "$THEME_DIR/Movies/titanfall_intro_cinematic.mp4"

# 3. THE HUD: Copy User Settings to the proper ConfigFile location
# According to metadata.desktop, ConfigFile=Themes/astronaut.conf
# SDDM expects the user override at Themes/astronaut.conf.user
# IMPORTANT: We COPY (not symlink) because the sddm user cannot traverse
# /home/rexsm to follow symlinks back into the dotfiles directory.

# First, remove any stale symlinks/files so cp doesn't fail with "same file"
sudo rm -f "$THEME_DIR/Themes/astronaut.conf.user"
sudo rm -f "$THEME_DIR/Themes/astronaut.confA"
sudo rm -f "$THEME_DIR/theme.conf.user"

# Now copy fresh
sudo cp "$DOTFILES_DIR/core/sddm/astronaut/theme.conf.user" "$THEME_DIR/Themes/astronaut.conf.user"

# 4. Permissions: Ensure SDDM user can read all deployed assets
sudo chown -R sddm:sddm "$THEME_DIR/Movies"
sudo chmod 644 "$THEME_DIR/Movies/titanfall_intro_cinematic.mp4"
sudo chmod 644 "$THEME_DIR/Themes/astronaut.conf.user"


# 8. WirePlumber Audio Protocol (Hardware-Agnostic)
echo "Deploying Audio Configuration for $TARGET..."

WP_SYSTEM_DIR="$HOME/.config/wireplumber/wireplumber.conf.d"
rm -rf "$WP_SYSTEM_DIR"
mkdir -p "$WP_SYSTEM_DIR"

# A. Link Universal Rules (Core)
safe_link "$DOTFILES_DIR/core/wireplumber/50-common-priorities.conf" "$WP_SYSTEM_DIR/50-common-priorities.conf"

# B. Link Host-Specific Quirks (If they exist for this machine)
HOST_WP_CONFIG="$DOTFILES_DIR/hosts/$TARGET/wireplumber/51-host-rescue.conf"
if [ -f "$HOST_WP_CONFIG" ]; then
    echo "Applying specific hardware rescue protocol for $TARGET..."
    safe_link "$HOST_WP_CONFIG" "$WP_SYSTEM_DIR/51-host-rescue.conf"
fi

# C. Refresh State: Wipe memory to ensure priorities take hold
systemctl --user stop wireplumber
rm -rf ~/.local/state/wireplumber/*
systemctl --user start wireplumber

echo "✅ Audio nominal. Pilot mic secured."


# 9. Mission Control (wtfutil)
echo "Deploying Mission Control Dashboard..."

if ! command -v wtfutil &> /dev/null; then
    paru -S --noconfirm wtfutil-bin
fi

# A. SECRETS PROTOCOL: Ensure the local secrets file exists for API keys
if [ ! -f "$HOME/.secrets.sh" ]; then
    echo "Initializing empty secrets vault at ~/.secrets.sh..."
    echo "#!/bin/bash" > "$HOME/.secrets.sh"
    echo "# Add your private API keys here (e.g., export WTF_OWM_API_KEY=\"...\")" >> "$HOME/.secrets.sh"
    echo "!!! MISSION DATA MISSING !!!: Please add your weather api for wtfutil to ~/.secrets.sh"
fi

echo "Protocol Complete. Welcome back, Pilot."