#!/usr/bin/env bash
# ~/.config/swaync/scripts/mic.sh
WPCTL="/usr/bin/wpctl"
NOTIFY="/usr/bin/notify-send"
STEP="5%"
TIMEOUT=1200  # milliseconds
CACHE="/tmp/current_mic_id"

notify() {
    $NOTIFY -t "$TIMEOUT" -u low "🎙️ Microphone" "$1"
}

# Detect or reuse cached mic ID
if [ -f "$CACHE" ]; then
    MIC_SOURCE=$(cat "$CACHE")
else
    MIC_SOURCE=$(wpctl status | awk '
        /Sources:/, /Filters:/ {
            if ($2 ~ /^[0-9]+\.$/ && $0 !~ /Easy Effects|Virtual|Monitor/) {
                gsub(/\./,"",$2);
                print $2;
                exit;
            }
        }')
    echo "$MIC_SOURCE" > "$CACHE"
fi

# If still empty, try fallback
if [ -z "$MIC_SOURCE" ]; then
    notify "❌ No active microphone found."
    exit 1
fi

case "$1" in
    up)
        $WPCTL set-volume "$MIC_SOURCE" "$STEP"+ --limit 1.0 ;;
    down)
        $WPCTL set-volume "$MIC_SOURCE" "$STEP"- ;;
    toggle)
        $WPCTL set-mute "$MIC_SOURCE" toggle ;;
    *)
        notify "Usage: mic.sh [up|down|toggle]"
        exit 1 ;;
esac

sleep 0.06

VOL_INFO=$($WPCTL get-volume "$MIC_SOURCE" 2>/dev/null)
if [ -z "$VOL_INFO" ]; then
    rm -f "$CACHE"
    notify "❌ Microphone became unavailable. Try again."
    exit 1
fi

if echo "$VOL_INFO" | grep -q "MUTED"; then
    notify "🔇 Microphone muted"
else
    VOL=$(echo "$VOL_INFO" | awk '{printf "%d", $2*100}')
    notify "🎙️ Volume: ${VOL}%"
fi
