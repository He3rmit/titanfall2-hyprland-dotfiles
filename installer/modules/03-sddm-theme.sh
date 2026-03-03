#!/bin/bash
# ==============================================================================
# MODULE: 03-sddm-theme.sh
# Purpose: Deploys the Astronaut SDDM theme and configuring cinematic movies.
# ==============================================================================

source "$INSTALLER_DIR/scripts/utils.sh"

print_step "Engaging SDDM Cinematic Protocol..."

THEME_NAME="sddm-astronaut-theme"
THEME_DIR="/usr/share/sddm/themes/$THEME_NAME"

# Check if SDDM theme is installed before proceeding
if [ ! -d "$THEME_DIR" ]; then
    print_error "Theme directory $THEME_DIR not found."
    print_warning "Please ensure $THEME_NAME is installed via paru."
    exit 1
fi

# 1. THE SWITCH: Enable the Theme in the global config
print_step ">> Linking sddm.conf override..."
sudo mkdir -p /etc/sddm.conf.d
sudo ln -sf "$DOTFILES_DIR/core/sddm/sddm.conf.d/theme.conf" "/etc/sddm.conf.d/theme.conf"

# 2. THE VIDEO: Deploy to 'Movies' (Standard for this theme)
print_step ">> Copying Cinematic Title Screen..."
sudo mkdir -p "$THEME_DIR/Movies"
sudo cp -u "$DOTFILES_DIR/core/sddm/astronaut/Movies/titanfall_intro_cinematic.mp4" "$THEME_DIR/Movies/titanfall_intro_cinematic.mp4"

# 3. THE HUD: Copy User Settings to the proper ConfigFile location
print_step ">> Applying Theme Override Preferences..."
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
print_step ">> Securing file permissions for sddm user..."
sudo chown -R sddm:sddm "$THEME_DIR/Movies"
sudo chown sddm:sddm "$THEME_DIR/Themes/astronaut.conf.user"
sudo chmod 644 "$THEME_DIR/Movies/titanfall_intro_cinematic.mp4"
sudo chmod 644 "$THEME_DIR/Themes/astronaut.conf.user"

print_success "SDDM Astronaut Configuration Deployed."
