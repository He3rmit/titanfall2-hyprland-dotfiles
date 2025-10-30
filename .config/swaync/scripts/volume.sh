#!/usr/bin/env bash
# volume.sh — system volume OSD with DND-proof notifications

WPCTL="/usr/bin/wpctl"
NOTIFY="/usr/bin/notify-send"
ID_FILE="/tmp/volume_notif_id"
STEP="5%"

case "$1" in
  up)     $WPCTL set-volume @DEFAULT_AUDIO_SINK@ "$STEP"+ ;;
  down)   $WPCTL set-volume @DEFAULT_AUDIO_SINK@ "$STEP"- ;;
  toggle) $WPCTL set-mute @DEFAULT_AUDIO_SINK@ toggle ;;
  *) echo "Usage: $0 {up|down|toggle}" >&2; exit 1 ;;
esac

sleep 0.08

OUT=$($WPCTL get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)

if echo "$OUT" | grep -qi "MUTED"; then
    VOL_PERC=0
    MUTED=true
else
    MUTED=false
    NUM=$(echo "$OUT" | grep -oP '\d+(\.\d+)?')
    if [[ "$NUM" == *.* ]]; then
        VOL_PERC=$(awk "BEGIN{printf \"%d\", $NUM*100}")
    else
        VOL_PERC=$NUM
    fi
fi

OLD_ID=0
[ -f "$ID_FILE" ] && OLD_ID=$(cat "$ID_FILE" 2>/dev/null || echo 0)

if [ "$MUTED" = true ]; then
    ICON="audio-volume-muted-symbolic"
    MSG="Muted"
    HINT_VAL=0
else
    ICON="audio-volume-high-symbolic"
    MSG="${VOL_PERC}%"
    HINT_VAL=$VOL_PERC
fi

NEW_ID=$($NOTIFY -p -t 1000 -r "$OLD_ID" -u critical -i "$ICON" -h int:value:"$HINT_VAL" "Volume" "$MSG")
[ -z "$NEW_ID" ] && NEW_ID=$OLD_ID
echo "$NEW_ID" > "$ID_FILE"
