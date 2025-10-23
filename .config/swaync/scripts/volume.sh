#!/usr/bin/env bash
# ~/.config/swaync/scripts/volume.sh
# Usage: volume.sh up|down|toggle
WPCTL="/usr/bin/wpctl"
NOTIFY="/usr/bin/notify-send"
ID_FILE="/tmp/volume_notif_id"
STEP="5%"   # volume step per key press

# adjust volume or toggle mute
case "$1" in
  up)
    $WPCTL set-volume @DEFAULT_AUDIO_SINK@ "$STEP"+
    ;;
  down)
    $WPCTL set-volume @DEFAULT_AUDIO_SINK@ "$STEP"-
    ;;
  toggle)
    $WPCTL set-mute @DEFAULT_AUDIO_SINK@ toggle
    ;;
  *)
    echo "Usage: $0 {up|down|toggle}" >&2
    exit 1
    ;;
esac

# small delay so hardware/software state has time to update
sleep 0.08

# read current volume and mute state
OUT=$($WPCTL get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)

if echo "$OUT" | grep -qi "MUTED"; then
    VOL_PERC=0
    MUTED=true
else
    MUTED=false
    # parse numeric value (can be float 0.0-1.0 or integer 0-100)
    NUM=$(echo "$OUT" | grep -oP '\d+(\.\d+)?')
    if [[ "$NUM" == *.* ]]; then
        # float format → convert to %
        VOL_PERC=$(awk "BEGIN{printf \"%d\", $NUM*100}")
    else
        # integer format → use directly
        VOL_PERC=$NUM
    fi
fi

# load previous notification id
OLD_ID=0
if [ -f "$ID_FILE" ]; then
    OLD_ID=$(cat "$ID_FILE" 2>/dev/null || echo 0)
fi

# choose icon and message
if [ "$MUTED" = "true" ]; then
    ICON="audio-volume-muted-symbolic"
    MSG="Volume muted"
    HINT_VAL=0
else
    ICON="audio-volume-high-symbolic"
    MSG="Volume: ${VOL_PERC}%"
    HINT_VAL=$VOL_PERC
fi

# send notification and capture id (replace previous)
NEW_ID=$($NOTIFY -p -t 1000 -r "$OLD_ID" -u low -i "$ICON" -h int:value:"$HINT_VAL" "Volume" "$MSG")
if [ -z "$NEW_ID" ]; then NEW_ID=$OLD_ID; fi
echo "$NEW_ID" > "$ID_FILE"
