#!/usr/bin/env bash
# brightness.sh — brightness control OSD, DND-proof

DEVICE="intel_backlight"
STEP="5%"
ID_FILE="/tmp/brightness_notif_id"
BRCTL="/usr/bin/brightnessctl"
NOTIFY="/usr/bin/notify-send"

case "$1" in
  up)   $BRCTL -d "$DEVICE" set +"$STEP" >/dev/null 2>&1 ;;
  down) $BRCTL -d "$DEVICE" set "$STEP"- >/dev/null 2>&1 ;;
  *) echo "Usage: $0 {up|down}" >&2; exit 1 ;;
esac

sleep 0.08

BRIGHT=$($BRCTL -d "$DEVICE" get 2>/dev/null)
MAX=$($BRCTL -d "$DEVICE" m 2>/dev/null)
[ -z "$BRIGHT" ] && [ -z "$MAX" ] && $NOTIFY -u critical "Brightness" "Error reading brightness" && exit 1

PERC=$(( BRIGHT * 100 / MAX ))

OLD_ID=0
[ -f "$ID_FILE" ] && OLD_ID=$(cat "$ID_FILE" 2>/dev/null || echo 0)

NEW_ID=$($NOTIFY -p -t 1000 -r "$OLD_ID" -u critical -i display-brightness-symbolic -h int:value:"$PERC" "Brightness" "${PERC}%")
[ -z "$NEW_ID" ] && NEW_ID=$OLD_ID
echo "$NEW_ID" > "$ID_FILE"
