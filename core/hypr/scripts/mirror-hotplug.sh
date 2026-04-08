#!/usr/bin/env bash

# ==============================================================================
# MIRROR HOTPLUG — Auto-Detect External Displays
# Cycles through: Laptop Only → External Only → Extend → Mirror
# ==============================================================================

STATE_FILE="/tmp/hypr-display-state"

# --- AUTO-DETECT ---
# Find the built-in display (eDP or LVDS)
LAPTOP=$(hyprctl monitors all -j | jq -r '.[] | select(.name | test("^eDP|^LVDS")) | .name' | head -1)

# Find the first external display (HDMI, DP, etc.)
EXTERNAL=$(hyprctl monitors all -j | jq -r '.[] | select(.name | test("^eDP|^LVDS") | not) | .name' | head -1)

# --- SAFETY CHECK ---
if [ -z "$LAPTOP" ]; then
    notify-send -u normal "Display" "No built-in display detected. This script is for laptops."
    exit 1
fi

if [ -z "$EXTERNAL" ]; then
    notify-send -u normal "Display" "No external monitor detected. Plug one in first."
    # Ensure laptop display is on
    hyprctl keyword monitor "$LAPTOP, preferred, auto, 1"
    echo "0" > "$STATE_FILE"
    exit 1
fi

# --- STATE LOGIC ---
if [ ! -f "$STATE_FILE" ]; then
    echo "0" > "$STATE_FILE"
fi

STATE=$(cat "$STATE_FILE")
NEXT_MODE=$(( (STATE + 1) % 4 ))

# --- EXECUTION ---
case $NEXT_MODE in
    0)
        notify-send -t 2000 "Display" "💻 Mode: Laptop Only"
        hyprctl keyword monitor "$LAPTOP, preferred, auto, 1"
        hyprctl keyword monitor "$EXTERNAL, disable"
        ;;
    1)
        notify-send -t 2000 "Display" "📺 Mode: External Only"
        hyprctl keyword monitor "$LAPTOP, disable"
        hyprctl keyword monitor "$EXTERNAL, preferred, auto, 1"
        ;;
    2)
        notify-send -t 2000 "Display" "↔️ Mode: Extend (Dual Monitor)"
        hyprctl keyword monitor "$LAPTOP, preferred, auto, 1"
        hyprctl keyword monitor "$EXTERNAL, preferred, auto-right, 1"
        ;;
    3)
        notify-send -t 2000 "Display" "🪞 Mode: Mirror (Presentation)"
        hyprctl keyword monitor "$LAPTOP, preferred, auto, 1"
        hyprctl keyword monitor "$EXTERNAL, preferred, auto, 1, mirror, $LAPTOP"
        ;;
esac

echo "$NEXT_MODE" > "$STATE_FILE"