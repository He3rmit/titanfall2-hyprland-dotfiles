#!/usr/bin/env bash
# ~/.config/swaync/scripts/touchpad.sh
# Usage: touchpad.sh toggle

NOTIFY="/usr/bin/notify-send"
ID_FILE="/tmp/touchpad_notif_id"

# Detect touchpad device name (only needs to match once)
DEVICE=$(swaymsg -t get_inputs | grep -oP '"identifier": "\K[^"]*touchpad[^"]*' | head -n 1)

if [ -z "$DEVICE" ]; then
  $NOTIFY "⚠️ No touchpad device found."
  exit 1
fi

# Check current state
STATE=$(swaymsg -t get_inputs | grep -A5 "$DEVICE" | grep '"send_events":' | grep -o '"[^"]*"$' | tr -d '"')

if [ "$STATE" = "disabled" ]; then
  swaymsg input "$DEVICE" events enabled
  MSG="Touchpad enabled"
  ICON="input-touchpad-symbolic"
else
  swaymsg input "$DEVICE" events disabled
  MSG="Touchpad disabled"
  ICON="input-touchpad-off-symbolic"
fi

# Load previous notification ID
OLD_ID=0
if [ -f "$ID_FILE" ]; then
  OLD_ID=$(cat "$ID_FILE" 2>/dev/null || echo 0)
fi

# Send notification and replace previous one
NEW_ID=$($NOTIFY -p -t 1200 -r "$OLD_ID" -i "$ICON" "$MSG")
if [ -z "$NEW_ID" ]; then NEW_ID=$OLD_ID; fi
echo "$NEW_ID" > "$ID_FILE"
