#!/usr/bin/env bash
# mic.sh — dynamic microphone control for Tiger Lake-LP onboard mic

ICON_MIC_MUTED="microphone-sensitivity-muted-symbolic"
ICON_MIC_ACTIVE="microphone-sensitivity-high-symbolic"
ID_FILE="/tmp/mic_notif_id"

SOURCE="70"
if ! wpctl get-volume $SOURCE &>/dev/null; then
    SOURCE="alsa_input.pci-0000_00_1f.3-platform-skl_hda_dsp_generic.pro-input-6"
fi

# --- perform action ---
case "$1" in
  toggle) wpctl set-mute $SOURCE toggle ;;
  up)     wpctl set-volume $SOURCE 5%+   ;;
  down)   wpctl set-volume $SOURCE 5%-   ;;
  *) echo "Usage: $0 {toggle|up|down}" >&2; exit 1 ;;
esac

sleep 0.08

# --- read current state ---
OUT=$(wpctl get-volume $SOURCE)
if echo "$OUT" | grep -q "MUTED"; then
    MUTED=true
else
    MUTED=false
fi

# extract 0.0–1.0 value
NUM=$(echo "$OUT" | grep -oP '[0-9.]+(?=$)')
if [[ "$NUM" == *.* ]]; then
    VOL_PERC=$(awk "BEGIN{printf \"%d\", $NUM*100}")
else
    VOL_PERC=$NUM
fi

# --- load previous notif id ---
OLD_ID=0
[ -f "$ID_FILE" ] && OLD_ID=$(cat "$ID_FILE" 2>/dev/null || echo 0)

# --- send notification ---
if [ "$MUTED" = true ]; then
    ICON="$ICON_MIC_MUTED"
    MSG="Muted"
    VAL=0
else
    ICON="$ICON_MIC_ACTIVE"
    MSG="Active — ${VOL_PERC}%"
    VAL=$VOL_PERC
fi

NEW_ID=$(notify-send -p -t 1000 -r "$OLD_ID" -u critical -i "$ICON" -h int:value:"$VAL" "Microphone" "$MSG")
[ -z "$NEW_ID" ] && NEW_ID=$OLD_ID
echo "$NEW_ID" > "$ID_FILE"
