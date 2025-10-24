#!/usr/bin/env bash

# Names of your outputs (check with `hyprctl devices` or `wlr-randr`)
LAPTOP="eDP-1"
EXTERNAL="HDMI-A-1"

# Get list of connected outputs
CONNECTED=$(hyprctl devices | grep "Output " | grep "Connected" | awk '{print $2}')

# Function to mirror
mirror() {
    hyprctl dispatch movewindow "output:$EXTERNAL pos 0 0" &>/dev/null
    hyprctl reload
}

# Check if external monitor is connected
if echo "$CONNECTED" | grep -q "$EXTERNAL"; then
    echo "External monitor detected, enabling mirror..."
    mirror
else
    echo "No external monitor, only laptop screen active."
fi
