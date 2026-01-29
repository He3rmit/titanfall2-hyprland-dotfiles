#!/bin/bash

# Get current profile
current=$(powerprofilesctl get)

# Cycle Logic: Performance -> Balanced -> Power Saver -> Performance
case "$current" in
    "performance")
        next="balanced"
        icon=""  # Battery Balanced Icon
        msg="SYSTEM BALANCED"
        ;;
    "balanced")
        next="power-saver"
        icon=""  # Battery Low/Saver Icon
        msg="ENERGY SAVER ENGAGED"
        ;;
    "power-saver")
        next="performance"
        icon=""  # Lightning/Performance Icon
        msg="MAX PERFORMANCE ENGAGED"
        ;;
    *)
        next="balanced"
        icon=""
        msg="SYSTEM BALANCED"
        ;;
esac

# Apply the new profile
powerprofilesctl set "$next"

# Send HUD Notification
notify-send -u low -i "$icon" "POWER PROTOCOL" "$msg"