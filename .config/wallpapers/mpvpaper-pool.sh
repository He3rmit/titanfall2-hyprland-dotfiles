#!/usr/bin/env bash
# Robust multi-monitor wallpaper manager for Hyprland
# Place: ~/.config/wallpapers/mpvpaper-next.sh
# Make executable: chmod +x ~/.config/wallpapers/mpvpaper-next.sh

set -euo pipefail
IFS=$'\n\t'

# ----------------------------
# Paths
# ----------------------------
XDG_RUNTIME_DIR="/run/user/$UID"
export XDG_RUNTIME_DIR
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-0}"

# Customize these to your directory structure
WALL_DIR="$HOME/dotfiles/.config/wallpapers/wallpaper-samples"
STATIC_DIR="$HOME/dotfiles/.config/wallpapers/wallpaper-samples"  # same as WALL_DIR for simplicity
TMP_DIR="${XDG_RUNTIME_DIR}/mpvpaper-next"
mkdir -p "$TMP_DIR"

# ----------------------------
# Config
# ----------------------------
INTERVAL=600                       # seconds per video wallpaper item
MPV_OPTS="--no-audio --loop --really-quiet --hwdec=auto-safe --no-terminal --image-display-duration=${INTERVAL}"

declare -A PIDS

# ----------------------------
# Power helpers
# ----------------------------
on_ac() {
    [[ -e /sys/class/power_supply/AC/online ]] && [[ "$(cat /sys/class/power_supply/AC/online)" == "1" ]]
}

battery_pct() {
    cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -n1 || echo 100
}

# ----------------------------
# Playlist and static picker
# ----------------------------
build_playlist() {
    find "$WALL_DIR" -type f \( -iname "*.mp4" -o -iname "*.webm" -o -iname "*.mkv" -o -iname "*.gif" -o -iname "*.png" -o -iname "*.jpg" \) | shuf
}

pick_static() {
    local file
    file=$(find "$STATIC_DIR" -maxdepth 1 -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" \) | shuf -n 1)
    if [[ -z "$file" ]]; then
        # fallback: pick any file from wallpaper-samples
        file=$(find "$WALL_DIR" -type f | shuf -n 1)
    fi
    echo "$file"
}

# ----------------------------
# Monitor helpers
# ----------------------------
get_monitors() {
    hyprctl monitors -j 2>/dev/null | jq -r '.[].name'
}

get_monitor_geometry() {
    local mon="$1"
    hyprctl monitors -j | jq -r ".[] | select(.name==\"$mon\") | \"\(.width)x\(.height)\""
}

# ----------------------------
# Launch wallpapers
# ----------------------------
start_monitor() {
    local mon="$1"
    local retries=5
    local file plist geom

    geom=$(get_monitor_geometry "$mon")

    if ! on_ac; then
        # Battery -> static image
        while (( retries-- )); do
            file=$(pick_static)
            mpvpaper -o "--no-audio --image-display-duration=inf --really-quiet --geometry=${geom} --keepaspect=no" "$mon" "$file" >/dev/null 2>&1 && break
        done
        PIDS[$mon]=$!
        echo "Static wallpaper on $mon (pid ${PIDS[$mon]})"
        return
    fi

    # AC -> playlist/video
    plist="$TMP_DIR/playlist-${mon}.txt"
    build_playlist > "$plist"
    mpvpaper -n "$INTERVAL" -o "$MPV_OPTS" "$mon" --playlist="$plist" >/dev/null 2>&1 &
    PIDS[$mon]=$!
    echo "Video wallpaper on $mon (pid ${PIDS[$mon]})"
}

# ----------------------------
# Cleanup on exit
# ----------------------------
cleanup() {
    echo "Stopping wallpapers..."
    for pid in "${PIDS[@]:-}"; do kill "$pid" 2>/dev/null || true; done
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

# ----------------------------
# Main loop
# ----------------------------
for mon in $(get_monitors); do
    start_monitor "$mon"
done

echo "All wallpapers started."
wait
