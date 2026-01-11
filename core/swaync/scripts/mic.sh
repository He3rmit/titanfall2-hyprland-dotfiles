#!/usr/bin/env bash
# ~/.config/swaync/scripts/mic.sh
WPCTL="/usr/bin/wpctl"
NOTIFY="/usr/bin/notify-send"
ID_FILE="/tmp/mic_notif_id"
STEP="5%"

if [ ! -x "$WPCTL" ]; then
  $NOTIFY -u critical "Mic" "wpctl not found at $WPCTL"
  exit 1
fi

# 1. TRANSMIT: Send the command to the audio source
case "$1" in
  up)    $WPCTL set-volume @DEFAULT_AUDIO_SOURCE@ "$STEP"+ ;;
  down)  $WPCTL set-volume @DEFAULT_AUDIO_SOURCE@ "$STEP"- ;;
  toggle) $WPCTL set-mute @DEFAULT_AUDIO_SOURCE@ toggle ;;
  *) echo "Usage: $0 {up|down|toggle}" >&2; exit 1 ;;
esac

# 2. PILOT'S WAIT LOOP: Wait for the source to respond (Self-Healing)
# This loop checks 5 times with a 0.1s delay. 
# It catches the device if it's "waking up" from a suspended state.
for i in {1..5}; do
    OUT=$($WPCTL get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null)
    if [ -n "$OUT" ]; then break; fi
    sleep 0.1
done

# 3. VERIFY: If after 0.5s there is still no output, report a telemetry failure
if [ -z "$OUT" ]; then
  $NOTIFY -u critical "Mic" "Telemetry Lost: Microphone source not responding."
  exit 1
fi

# 4. PARSE: Extract volume and mute status
if echo "$OUT" | grep -qi "MUTED"; then
  VOL_PERC=0
  MUTED=true
else
  MUTED=false
  # Robust parsing for both percentage and decimal outputs
  VOL_PERC=$(echo "$OUT" | awk '{
    for(i=1;i<=NF;i++){
      if($i ~ /[0-9]+%/){ gsub(/[^0-9]/,"",$i); print $i; exit }
    }
  }')
  if [ -z "$VOL_PERC" ]; then
    VOL_PERC=$(echo "$OUT" | awk '{ for(i=1;i<=NF;i++) if($i ~ /[0-9]+\.[0-9]+/){ printf "%d", $i*100; exit } }')
  fi
  VOL_PERC=${VOL_PERC:-0}
fi

# 5. NOTIFY: Update the SwayNC HUD
OLD_ID=0
if [ -f "$ID_FILE" ]; then OLD_ID=$(cat "$ID_FILE" 2>/dev/null || echo 0); fi

if [ "$MUTED" = "true" ]; then
  ICON="microphone-sensitivity-muted-symbolic"
  MSG="Microphone muted"
  HINT_VAL=0
else
  ICON="microphone-sensitivity-high-symbolic"
  MSG="Microphone: ${VOL_PERC}%"
  HINT_VAL=$VOL_PERC
fi

NEW_ID=$($NOTIFY -p -t 1200 -r "$OLD_ID" -u low -i "$ICON" -h int:value:"$HINT_VAL" "Microphone" "$MSG")
if [ -z "$NEW_ID" ]; then NEW_ID=$OLD_ID; fi
echo "$NEW_ID" > "$ID_FILE"
exit 0