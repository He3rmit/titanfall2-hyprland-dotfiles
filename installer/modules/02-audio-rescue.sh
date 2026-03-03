#!/bin/bash
# ==============================================================================
# MODULE: 02-audio-rescue.sh
# Purpose: Deploys the Wireplumber configuration safely and restarts the daemon.
# ==============================================================================

source "$INSTALLER_DIR/scripts/utils.sh"

print_step "Deploying Audio Configuration for $TARGET..."

WP_SYSTEM_DIR="$HOME/.config/wireplumber/wireplumber.conf.d"
# We DO NOT rm -rf the directory here. Let safe_link handle individual files.
mkdir -p "$WP_SYSTEM_DIR"

# A. Link Universal Rules (Core)
safe_link "$DOTFILES_DIR/core/wireplumber/50-common-priorities.conf" "$WP_SYSTEM_DIR/50-common-priorities.conf"

# B. Link Host-Specific Quirks (If they exist for this machine)
HOST_WP_CONFIG="$DOTFILES_DIR/hosts/$TARGET/wireplumber/51-host-rescue.conf"
if [ -f "$HOST_WP_CONFIG" ]; then
    print_step "Applying specific hardware rescue protocol for $TARGET..."
    safe_link "$HOST_WP_CONFIG" "$WP_SYSTEM_DIR/51-host-rescue.conf"
fi

# C. Refresh State: Wipe memory to ensure priorities take hold
print_step "Clearing audio cache and restarting Wireplumber..."
systemctl --user stop wireplumber
rm -rf ~/.local/state/wireplumber/*
systemctl --user start wireplumber

print_success "Audio nominal. Pilot mic secured."
