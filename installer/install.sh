#!/bin/bash
# ==============================================================================
# TITANFALL PILOT HUD — DEPLOYMENT TERMINAL
# ==============================================================================

cd "$(dirname "$0")" || exit 1
INSTALLER_DIR=$(pwd)
DOTFILES_DIR=$(dirname "$INSTALLER_DIR")
export INSTALLER_DIR DOTFILES_DIR

source "$INSTALLER_DIR/scripts/utils.sh"

# ── 0. ENSURE GUM ──────────────────────────────────────────────────────────────
if ! command -v gum &> /dev/null; then
    echo "Installing 'gum' for Deployment UI..."
    aur_install gum
fi

clear

# ── 1. SPLASH SCREEN ───────────────────────────────────────────────────────────
gum style \
    --border double \
    --border-foreground 51 \
    --foreground 51 \
    --bold \
    --margin "1 4" \
    --padding "1 8" \
    "████████╗██╗████████╗ █████╗ ███╗   ██╗███████╗ █████╗ ██╗     ██╗" \
    "╚══██╔══╝██║╚══██╔══╝██╔══██╗████╗  ██║██╔════╝██╔══██╗██║     ██║" \
    "   ██║   ██║   ██║   ███████║██╔██╗ ██║█████╗  ███████║██║     ██║" \
    "   ██║   ██║   ██║   ██╔══██║██║╚██╗██║██╔══╝  ██╔══██║██║     ██║" \
    "   ██║   ██║   ██║   ██║  ██║██║ ╚████║██║     ██║  ██║███████╗███████╗" \
    "   ╚═╝   ╚═╝   ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝     ╚═╝  ╚═╝╚══════╝╚══════╝"

gum style \
    --foreground 244 \
    --align center \
    --margin "0 4" \
    "PILOT HUD  //  DEPLOYMENT TERMINAL  //  v2.1"

echo ""

# ── 2. AUTHORIZATION ───────────────────────────────────────────────────────────
gum style --foreground 214 --bold "[ PILOT AUTHORIZATION ]"
keep_sudo_alive

# ── 3. HOST PROFILE SELECTION ──────────────────────────────────────────────────
echo ""
gum style --foreground 51 --bold "Select Deployment Profile:"

# Build profile list dynamically from hosts/ (exclude _template)
PROFILES=()
for dir in "$DOTFILES_DIR"/hosts/*/; do
    name=$(basename "$dir")
    [[ "$name" == "_template" ]] && continue
    # Read profile.conf for description if it exists
    if [[ -f "$dir/profile.conf" ]]; then
        source "$dir/profile.conf"
        PROFILES+=("$name  ($HOST_TYPE)")
    else
        PROFILES+=("$name")
    fi
done
PROFILES+=("+ Create New Profile")

SELECTION=$(printf '%s\n' "${PROFILES[@]}" | gum choose)

if [[ "$SELECTION" == "+ Create New Profile" ]]; then
    echo ""
    gum style --foreground 214 --bold "[ NEW PROFILE SETUP ]"
    
    PROFILE_TYPE=$(gum choose "laptop" "desktop")
    PROFILE_NAME=$(gum input --placeholder "Enter a name for this profile (e.g., thinkpad-garuda)")
    
    if [[ -z "$PROFILE_NAME" ]]; then
        print_error "Profile name cannot be empty."
        exit 1
    fi

    # Keyboard Layout Selection
    print_step ">> Configuring Input Methods..."
    KB_LAYOUT=$(gum input --placeholder "Enter Keyboard Layout (e.g. us, fr, de, jp)" --value "us")
    KB_VARIANT=$(gum input --placeholder "Enter Keyboard Variant (optional, e.g. mac, dvorak)")
    
    NEW_DIR="$DOTFILES_DIR/hosts/$PROFILE_NAME"
    if [[ -d "$NEW_DIR" ]]; then
        print_error "Profile '$PROFILE_NAME' already exists."
        exit 1
    fi
    
    cp -r "$DOTFILES_DIR/hosts/_template/$PROFILE_TYPE" "$NEW_DIR"
    
    # Rename .example files
    for f in "$NEW_DIR"/*.example; do
        [[ -f "$f" ]] && mv "$f" "${f%.example}"
    done
    
    # Update the profile.conf with the user's name and keyboard settings
    sed -i "s/HOST_NAME=.*/HOST_NAME=\"$PROFILE_NAME\"/" "$NEW_DIR/profile.conf"
    sed -i "s/KB_LAYOUT=.*/KB_LAYOUT=\"$KB_LAYOUT\"/" "$NEW_DIR/profile.conf"
    sed -i "s/KB_VARIANT=.*/KB_VARIANT=\"$KB_VARIANT\"/" "$NEW_DIR/profile.conf"
    
    # --- Monitor & Scaling Wizard ---
    echo ""
    gum style --foreground 214 --bold "Display Calibration:"
    
    # Try to detect monitor name
    DETECTED_MONITOR=$(hyprctl monitors -j | jq -r '.[0].name' 2>/dev/null || echo "auto")
    MONITOR_NAME=$(gum input --placeholder "Monitor Name (e.g. eDP-1, DP-1 or auto)" --value "$DETECTED_MONITOR")
    
    # Scaling factor
    echo "Select Scaling Factor (1.0 = Default, 1.25+ = High DPI):"
    SCALE=$(gum choose "1.0" "1.25" "1.5" "2.0")
    
    sed -i "s/MONITOR_NAME=.*/MONITOR_NAME=\"$MONITOR_NAME\"/" "$NEW_DIR/profile.conf"
    sed -i "s/SCALE=.*/SCALE=\"$SCALE\"/" "$NEW_DIR/profile.conf"
    
    print_success "Display Profile configured: $MONITOR_NAME at ${SCALE}x scaling."
    
    print_success "Profile '$PROFILE_NAME' created from $PROFILE_TYPE template."
    gum style --foreground 214 "You can customize files in: hosts/$PROFILE_NAME/"
    TARGET="$PROFILE_NAME"
else
    # Extract just the profile name (strip the description)
    TARGET=$(echo "$SELECTION" | awk '{print $1}')
fi

export TARGET

if [ ! -d "$DOTFILES_DIR/hosts/$TARGET" ]; then
    print_error "Host configuration for '$TARGET' not found."
    exit 1
fi

if [[ -f "$DOTFILES_DIR/hosts/$TARGET/profile.conf" ]]; then
    source "$DOTFILES_DIR/hosts/$TARGET/profile.conf"
    export HOST_TYPE HOST_NAME HAS_BATTERY HAS_BACKLIGHT HAS_TOUCHPAD KB_LAYOUT KB_VARIANT MONITOR_NAME SCALE
fi

print_success "Target locked: $TARGET ($HOST_TYPE)"

# ── 4. MODULE SELECTION ────────────────────────────────────────────────────────
echo ""
gum style --foreground 51 --bold "Select Modules to Deploy:"
gum style --foreground 244 \
    "  00-dependencies   — Install all system and AUR packages" \
    "  01-stow-configs   — Symlink dotfiles into ~/.config" \
    "  02-audio-rescue   — Deploy Wireplumber audio config" \
    "  03-sddm-theme     — Install the Astronaut SDDM login theme"
echo ""
gum style --foreground 244 "(SPACE to select, ENTER to confirm)"
echo ""

MODULES=$(gum choose --no-limit \
    "00-dependencies" \
    "01-stow-configs" \
    "02-audio-rescue" \
    "03-sddm-theme")

if [ -z "$MODULES" ]; then
    print_warning "No modules selected. Aborting."
    exit 0
fi

# ── 5. CONFIRMATION ────────────────────────────────────────────────────────────
echo ""
gum style --foreground 51 --bold "Deployment Manifest:"
echo "$MODULES" | while read -r m; do
    gum style --foreground 46 "  ✓ $m"
done
echo ""

if ! gum confirm "Initiate deployment to [$TARGET]?"; then
    print_warning "Deployment aborted by Pilot."
    exit 0
fi

# ── 6. EXECUTION ───────────────────────────────────────────────────────────────
echo ""
IFS=$'\n' read -rd '' -a SELECTED_MODULES <<< "$MODULES"

for module in "${SELECTED_MODULES[@]}"; do
    module_script="$INSTALLER_DIR/modules/${module}.sh"

    if [ -f "$module_script" ]; then
        echo ""
        gum spin --spinner dot --title " Deploying: $module..." -- bash "$module_script"

        if [ $? -ne 0 ]; then
            print_error "Module '$module' failed. Aborting."
            exit 1
        fi
        print_success "$module deployed."
    else
        print_error "Module script not found: $module_script"
    fi
done

# ── 7. SIGN-OFF ────────────────────────────────────────────────────────────────
echo ""
gum style \
    --border rounded \
    --border-foreground 46 \
    --foreground 46 \
    --bold \
    --padding "1 4" \
    --margin "1 2" \
    "DEPLOYMENT COMPLETE" \
    "Welcome back, Pilot."
