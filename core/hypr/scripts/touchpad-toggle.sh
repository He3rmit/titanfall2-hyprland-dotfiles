#!/usr/bin/env bash

# --- TITAN CONFIGURATION ---
# The file that holds the state
STATE_FILE="$HOME/.config/hypr/touchpad.conf"

# Auto-detect the touchpad device
DEVICE=$(hyprctl devices -j 2>/dev/null | jq -r '.mice[] | select(.name | test("touchpad"; "i")) | .name' | head -1)

if [ -z "$DEVICE" ]; then
    notify-send -u low -i input-touchpad-off "Touchpad" "No touchpad device detected"
    exit 0
fi

# Create state file with defaults if it doesn't exist
if [ ! -f "$STATE_FILE" ]; then
    echo "device {
    name = $DEVICE
    enabled = true
}" > "$STATE_FILE"
fi

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