#!/usr/bin/env bash
# ~/.config/swaync/scripts/brightness.sh
DEVICE=$(ls /sys/class/backlight/ 2>/dev/null | head -n 1)
if [ -z "$DEVICE" ]; then
    notify-send -u critical "Brightness" "No backlight device found"
    exit 1
fi
STEP="5%"                           
ID_FILE="/tmp/brightness_notif_id"  
BRCTL="/usr/bin/brightnessctl"
NOTIFY="/usr/bin/notify-send"

case "$1" in
  up)  $BRCTL -d "$DEVICE" set +"$STEP" >/dev/null 2>&1 ;;
  down) $BRCTL -d "$DEVICE" set "$STEP"- >/dev/null 2>&1 ;;
  *) echo "Usage: $0 {up|down}" >&2; exit 1 ;;
esac

sleep 0.08

BRIGHT=$($BRCTL -d "$DEVICE" get 2>/dev/null)
MAX=$($BRCTL -d "$DEVICE" m 2>/dev/null)
if [ -z "$BRIGHT" ] || [ -z "$MAX" ] || [ "$MAX" -eq 0 ]; then
  $NOTIFY -u critical "Brightness" "Unable to read brightness"
  exit 1
fi

PERC=$(( BRIGHT * 100 / MAX ))
OLD_ID=0
if [ -f "$ID_FILE" ]; then OLD_ID=$(cat "$ID_FILE" 2>/dev/null || echo 0); fi

NEW_ID=$($NOTIFY -p -t 1200 -r "$OLD_ID" -u low -h int:value:"$PERC" -i display-brightness-symbolic "Brightness" "${PERC}%")
if [ -z "$NEW_ID" ]; then NEW_ID="$OLD_ID"; fi
echo "$NEW_ID" > "$ID_FILE"