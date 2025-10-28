#!/usr/bin/env bash
# ✨ Hybrid Dynamic Wallpaper Manager for Hyprland + mpvpaper
# Supports shuffling, fade transitions, timed rotation, and battery pause/resume

WALL_DIR="$HOME/.config/wallpapers/wallpaper-samples"
STATIC_DIR="$HOME/.config/wallpapers/static"
CHANGE_INTERVAL=$((20 * 60))   # ⏱️ default 20 minutes (in seconds)
FADE_SCRIPT="$HOME/.config/wallpapers/fade.lua"
LOG_TAG="[mpvpaper-pool]"
HYPR_SOCKET=$(ls /run/user/$UID/hypr/*/.socket2.sock 2>/dev/null | head -n 1)

echo "$LOG_TAG Using Hypr socket: $HYPR_SOCKET"

# --- Function: pick all wallpapers, shuffle them ---
build_playlist() {
    mapfile -t ALL_WALLS < <(find "$WALL_DIR" "$STATIC_DIR" -type f \( -iname '*.mp4' -o -iname '*.jpg' -o -iname '*.png' -o -iname '*.jpeg' \))
    if [[ ${#ALL_WALLS[@]} -eq 0 ]]; then
        echo "$LOG_TAG ⚠️ No wallpapers found!"
        exit 1
    fi
    # Shuffle
    SHUFFLED=($(shuf -e "${ALL_WALLS[@]}"))
}

# --- Function: launch mpvpaper with fade + fullscreen ---
launch_mpvpaper() {
    local MONITOR=$1
    local FILE=$2
    echo "$LOG_TAG Launching on $MONITOR → $FILE"
    mpvpaper -o "--script=$FADE_SCRIPT --no-audio --loop --fullscreen --keep-open=yes --geometry=0:0 --fs --no-keepaspect --video-unscaled=no --autofit-larger=100%x100%" "$MONITOR" "$FILE" &
    MPV_PIDS["$MONITOR"]=$!
}

# --- Function: stop existing mpvpaper instance ---
stop_mpvpaper() {
    local MONITOR=$1
    if [[ -n "${MPV_PIDS[$MONITOR]}" ]]; then
        kill "${MPV_PIDS[$MONITOR]}" 2>/dev/null
        unset MPV_PIDS["$MONITOR"]
    fi
}

# --- Function: check power status ---
on_battery() {
    [[ "$(cat /sys/class/power_supply/AC/online 2>/dev/null)" == "0" ]]
}

# --- Main execution ---
echo "$LOG_TAG Starting wallpaper pool..."
build_playlist

mapfile -t MONITORS < <(hyprctl -j monitors | jq -r '.[].name')
declare -A MPV_PIDS
INDEX=0

while true; do
    for MONITOR in "${MONITORS[@]}"; do
        # Ensure valid index
        FILE="${SHUFFLED[$INDEX]}"
        [[ -z "$FILE" ]] && { build_playlist; INDEX=0; FILE="${SHUFFLED[$INDEX]}"; }

        stop_mpvpaper "$MONITOR"
        launch_mpvpaper "$MONITOR" "$FILE"

        ((INDEX++))
    done

    for ((i=0; i<CHANGE_INTERVAL; i+=5)); do
        if on_battery; then
            for pid in "${MPV_PIDS[@]}"; do
                kill -STOP "$pid" 2>/dev/null
            done
            echo "$LOG_TAG 🔋 On battery — paused wallpapers"
        else
            for pid in "${MPV_PIDS[@]}"; do
                kill -CONT "$pid" 2>/dev/null
            done
        fi
        sleep 5
    done
done
