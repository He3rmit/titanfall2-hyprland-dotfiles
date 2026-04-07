#!/bin/bash
# ==============================================================================
# MODULE: 03-sddm-theme.sh
# Purpose: Deploys the Astronaut SDDM theme and configuring cinematic movies.
#          Hardened for Garuda Linux and Arch-based variety.
# ==============================================================================

source "$INSTALLER_DIR/scripts/utils.sh"

print_step "Engaging SDDM Cinematic Protocol..."

# --- 1. THEME DETECTION ---
# Some users install 'sddm-astronaut-theme', others 'sddm-theme-astronaut'
POSSIBLE_THEMES=(
    "/usr/share/sddm/themes/sddm-astronaut-theme"
    "/usr/share/sddm/themes/sddm-theme-astronaut"
)

THEME_DIR=""
for dir in "${POSSIBLE_THEMES[@]}"; do
    if [ -d "$dir" ]; then
        THEME_DIR="$dir"
        break
    fi
done

if [ -z "$THEME_DIR" ]; then
    print_error "Astronaut SDDM Theme not found in system directories."
    print_warning "Please ensure 'sddm-astronaut-theme' is installed via AUR."
    exit 1
fi

print_success "Theme located at: $THEME_DIR"

# --- 2. THE SWITCH (Priority Override) ---
# We use '00-theme.conf' to ensure it lexicographically overrides 
# 'garuda.conf' or 'default.conf' which usually start with higher numbers.
print_step ">> Linking sddm.conf override (High Priority)..."
sudo mkdir -p /etc/sddm.conf.d

# Find existing configs and warn if they might conflict
CONFLICTS=$(ls /etc/sddm.conf.d/ | grep -v "00-theme.conf")
if [ -n "$CONFLICTS" ]; then
    print_warning "Found existing SDDM configs: $CONFLICTS"
    print_warning "These may be overridden by our 00-theme.conf."
fi

sudo ln -sf "$DOTFILES_DIR/core/sddm/sddm.conf.d/00-theme.conf" "/etc/sddm.conf.d/00-theme.conf"

# --- 3. THE VIDEO ---
print_step ">> Copying Cinematic Title Screen..."
sudo mkdir -p "$THEME_DIR/Movies"
sudo cp -u "$DOTFILES_DIR/core/sddm/astronaut/Movies/titanfall_intro_cinematic.mp4" "$THEME_DIR/Movies/titanfall_intro_cinematic.mp4"

# --- 4. THE HUD (Dual Deployment) ---
# We copy to BOTH potential locations to support all theme versions (v1.x and v2.x)
print_step ">> Applying Theme Override Preferences (Dual-Path)..."

# Target A: Root folder (Standard)
sudo cp "$DOTFILES_DIR/core/sddm/astronaut/theme.conf.user" "$THEME_DIR/theme.conf.user"

# Target B: Themes subfolder (Specific Astronaut structure)
if [ -d "$THEME_DIR/Themes" ]; then
    sudo cp "$DOTFILES_DIR/core/sddm/astronaut/theme.conf.user" "$THEME_DIR/Themes/astronaut.conf.user"
fi

# --- 5. Permissions ---
print_step ">> Securing file permissions for sddm user..."
sudo chown -R sddm:sddm "$THEME_DIR/Movies"
[ -f "$THEME_DIR/theme.conf.user" ] && sudo chown sddm:sddm "$THEME_DIR/theme.conf.user"
[ -f "$THEME_DIR/Themes/astronaut.conf.user" ] && sudo chown sddm:sddm "$THEME_DIR/Themes/astronaut.conf.user"

sudo chmod 644 "$THEME_DIR/Movies/titanfall_intro_cinematic.mp4"
[ -f "$THEME_DIR/theme.conf.user" ] && sudo chmod 644 "$THEME_DIR/theme.conf.user"
[ -f "$THEME_DIR/Themes/astronaut.conf.user" ] && sudo chmod 644 "$THEME_DIR/Themes/astronaut.conf.user"

print_success "SDDM Astronaut Configuration Deployed."
