#!/usr/bin/env bash

LAPTOP="eDP-1"
EXTERNAL="HDMI-A-1"
STATE_FILE="/tmp/hypr-display-state"

# Read last mode or default to 0
STATE=$(cat "$STATE_FILE" 2>/dev/null || echo 0)

# Modes:
# 0 - laptop only
# 1 - external only
# 2 - extend
# 3 - mirror

next_mode=$(( (STATE + 1) % 4 ))

case $next_mode in
    0)
        echo "Laptop only"
        hyprctl dispatch output "$LAPTOP,enable,mode=1920x1080@60,pos=0,0"
        hyprctl dispatch output "$EXTERNAL,disable"
        ;;
    1)
        echo "External only"
        hyprctl dispatch output "$LAPTOP,disable"
        hyprctl dispatch output "$EXTERNAL,enable,mode=1920x1080@60,pos=0,0"
        ;;
    2)
        echo "Extend right"
        hyprctl dispatch output "$LAPTOP,enable,mode=1920x1080@60,pos=0,0"
        hyprctl dispatch output "$EXTERNAL,enable,mode=1920x1080@60,pos=1920,0"
        ;;
    3)
        echo "Mirror mode"
        hyprctl dispatch output "$LAPTOP,enable,mode=1920x1080@60,pos=0,0"
        hyprctl dispatch output "$EXTERNAL,enable,mode=1920x1080@60,pos=0,0"
        ;;
esac

echo "$next_mode" > "$STATE_FILE"
