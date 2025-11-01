#!/usr/bin/env bash
# ~/.config/swaync/scripts/brightness.sh
# Brightness control + in-place notification (same pattern as volnotif)

DEVICE="intel_backlight"                # <- change if needed (use `brightnessctl -l` to check)
STEP="5%"                               # brightness adjustment step
ID_FILE="/tmp/brightness_notif_id"      # persistent per-session notif id
BRCTL="/usr/bin/brightnessctl"
NOTIFY="/usr/bin/notify-send"

case "$1" in
  up)   $BRCTL -d "$DEVICE" set +"$STEP" >/dev/null 2>&1 ;;
  down) $BRCTL -d "$DEVICE" set "$STEP"- >/dev/null 2>&1 ;;
  *)    echo "Usage: $0 {up|down}" >&2; exit 1 ;;
esac

# small delay so hardware state has time to reflect
sleep 0.08

# read current values (fail-safe)
BRIGHT=$($BRCTL -d "$DEVICE" get 2>/dev/null)
MAX=$($BRCTL -d "$DEVICE" m 2>/dev/null)

if [ -z "$BRIGHT" ] || [ -z "$MAX" ] || [ "$MAX" -eq 0 ]; then
  $NOTIFY -u critical "Brightness" "Unable to read brightness"
  exit 1
fi

PERC=$(( BRIGHT * 100 / MAX ))

# load previous id if present
if [ -f "$ID_FILE" ]; then
  OLD_ID=$(cat "$ID_FILE" 2>/dev/null || echo 0)
else
  OLD_ID=0
fi

# send and capture the notification id
NEW_ID=$($NOTIFY -p -t 1200 -r "$OLD_ID" -u low \
  -h int:value:"$PERC" -i display-brightness-symbolic \
  "Brightness" "${PERC}%")

if [ -z "$NEW_ID" ]; then NEW_ID="$OLD_ID"; fi
echo "$NEW_ID" > "$ID_FILE"
