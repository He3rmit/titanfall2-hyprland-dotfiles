#!/bin/bash
# ==============================================================================
# TITANFALL HUD - MODULAR INSTALLER
# ==============================================================================
# This is the main entry point for the dotfiles installation.
# It uses 'gum' to provide a highly interactive Terminal UI.
# ==============================================================================

# Ensure we are in the script directory
cd "$(dirname "$0")" || exit 1
INSTALLER_DIR=$(pwd)
DOTFILES_DIR=$(dirname "$INSTALLER_DIR")
export INSTALLER_DIR DOTFILES_DIR

# Import utilities
source "$INSTALLER_DIR/scripts/utils.sh"

# 1. Dependency Check
if ! command -v gum &> /dev/null; then
    echo "⚠️  'gum' is not installed. We need it for the UI."
    echo "Installing gum via paru..."
    if ! command -v paru &> /dev/null; then
        echo "❌ paru not found. Please install paru first (or run the old install.sh)."
        exit 1
    fi
    paru -S --noconfirm gum
fi

clear
print_step "=============================================="
print_step "      TITANFALL PILOT HUD DEPLOYMENT          "
print_step "=============================================="
echo ""

# 2. Authorization
keep_sudo_alive

# 3. Host Selection (Replaces argument passing)
echo ""
print_step "Select Deployment Target:"
TARGET=$(gum choose "laptop" "desktop")
export TARGET

# Validate Target
if [ ! -d "$DOTFILES_DIR/hosts/$TARGET" ]; then
    print_error "Host configuration for '$TARGET' not found."
    exit 1
fi
print_success "Target locked: $TARGET"

# 4. Module Selection Menu
echo ""
print_step "Select Operational Modules to Deploy:"
echo "(Use SPACE to select/deselect, ENTER to confirm)"
echo ""

# Define the modules available
MODULES=$(gum choose --no-limit \
    "00-dependencies" \
    "01-stow-configs" \
    "02-audio-rescue" \
    "03-sddm-theme" \
    "04-mission-control")

if [ -z "$MODULES" ]; then
    print_warning "No modules selected. Aborting deployment."
    exit 0
fi

# 5. Execution Loop
echo ""
print_step "Initiating Deployment Sequence..."
echo ""

# Convert multi-line output from gum into an array
IFS=$'\n' read -rd '' -a SELECTED_MODULES <<< "$MODULES"

for module in "${SELECTED_MODULES[@]}"; do
    module_script="$INSTALLER_DIR/modules/${module}.sh"
    
    if [ -f "$module_script" ]; then
        print_step ">> Executing: $module"
        bash "$module_script"
        
        # Check exit status
        if [ $? -ne 0 ]; then
            print_error "Module '$module' failed. Aborting."
            exit 1
        fi
    else
        print_error "Module script not found: $module_script"
    fi
done

echo ""
print_success "Deployment Complete. Welcome back, Pilot."
