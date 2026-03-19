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

# ── 3. HOST SELECTION ──────────────────────────────────────────────────────────
echo ""
gum style --foreground 51 --bold "Select Deployment Target:"
TARGET=$(gum choose "laptop" "desktop")
export TARGET

if [ ! -d "$DOTFILES_DIR/hosts/$TARGET" ]; then
    print_error "Host configuration for '$TARGET' not found."
    exit 1
fi
print_success "Target locked: $TARGET"

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
