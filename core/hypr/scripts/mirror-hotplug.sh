#!/usr/bin/env bash

# --- CONFIGURATION ---
LAPTOP="eDP-1"
EXTERNAL="HDMI-A-1" # Check 'hyprctl monitors all' to verify this name!
STATE_FILE="/tmp/hypr-display-state"

# --- SAFETY CHECK: Is the cable actually plugged in? ---
# We grep for the port name in the connected list. 
# If it's not found, we force Laptop Only mode.
if ! hyprctl monitors all | grep -q "$EXTERNAL"; then
    echo "⚠️ No external monitor detected! Forcing Laptop Only."
    hyprctl keyword monitor "$LAPTOP, preferred, auto, 1"
    hyprctl keyword monitor "$EXTERNAL, disable"
    echo "0" > "$STATE_FILE"
    exit 1
fi

# --- STATE LOGIC ---
# Read last mode or default to 0
if [ ! -f "$STATE_FILE" ]; then
    echo "0" > "$STATE_FILE"
fi

STATE=$(cat "$STATE_FILE")
NEXT_MODE=$(( (STATE + 1) % 4 ))

# --- EXECUTION ---
case $NEXT_MODE in
    0)
        echo "💻 Mode: Laptop Only"
        hyprctl keyword monitor "$LAPTOP, preferred, auto, 1"
        hyprctl keyword monitor "$EXTERNAL, disable"
        ;;
    1)
        echo "📺 Mode: External Only"
        hyprctl keyword monitor "$LAPTOP, disable"
        hyprctl keyword monitor "$EXTERNAL, preferred, auto, 1"
        ;;
    2)
        echo "↔️ Mode: Extend (Dual Monitor)"
        hyprctl keyword monitor "$LAPTOP, preferred, auto, 1"
        # Places external to the right of laptop
        hyprctl keyword monitor "$EXTERNAL, preferred, auto-right, 1"
        ;;
    3)
        echo "🪞 Mode: Mirror (Presentation)"
        hyprctl keyword monitor "$LAPTOP, preferred, auto, 1"
        hyprctl keyword monitor "$EXTERNAL, preferred, auto, 1, mirror, $LAPTOP"
        ;;
esac

# Save state
echo "$NEXT_MODE" > "$STATE_FILE"