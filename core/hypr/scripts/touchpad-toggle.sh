#!/usr/bin/env bash

# --- TITAN CONFIGURATION ---
# The file that holds the state
STATE_FILE="$HOME/.config/hypr/touchpad.conf"

# The specific ASUS device ID
DEVICE="asue1305:00-04f3:3212-touchpad"

# Check if the file currently says "enabled = false"
if grep -q "enabled = false" "$STATE_FILE"; then
    # TOGGLE ON: Enable it
    echo "device {
        name = $DEVICE
        enabled = true
    }" > "$STATE_FILE"
    notify-send -u low -i input-touchpad-on "Touchpad" "Enabled ✅"
else
    # TOGGLE OFF: Disable it
    echo "device {
        name = $DEVICE
        enabled = false
    }" > "$STATE_FILE"
    notify-send -u low -i input-touchpad-off "Touchpad" "Disabled 🚫"
fi

# Reload Hyprland to apply the new file
# (This does NOT restart your session, just re-reads configs)
hyprctl reload