#!/usr/bin/env bash
# ───────────────────────────────────────────────
# mpvpaper-pool.sh — dynamic shuffled wallpaper rotator with AC/battery handling + fade
# Full-featured Rex Edition
# ───────────────────────────────────────────────

LOG_PREFIX="[mpvpaper-pool]"
WALL_DIR="$HOME/.config/wallpapers/wallpaper-samples"
STATIC_DIR="$HOME/.config/wallpapers/static"
CHANGE_INTERVAL=$((20 * 60))   # 20 minutes (configurable)
FADE_SCRIPT="$HOME/.config/wallpapers/fade.lua"
FADE_DURATION=1.5               # seconds, configurable

# --- Setup environment ---
export XDG_RUNTIME_DIR="/run/user/$(id -u)"
HYPR_SOCKET=$(ls /run/user/$(id -u)/hypr/*.sock* 2>/dev/null | head -n 1 || true)

echo "$LOG_PREFIX Using Hypr socket: ${HYPR_SOCKET:-none}"
echo "$LOG_PREFIX mpvpaper-pool starting..."

# --- Detect monitors ---
MONITORS=$(hyprctl monitors -j | jq -r '.[].name')
if [[ -z "$MONITORS" ]]; then
    echo "$LOG_PREFIX ❌ No monitors found. Exiting."
    exit 1
fi
echo "$LOG_PREFIX Detected monitors: $MONITORS"

# --- Build playlist ---
build_playlist() {
    mapfile -t WALLPAPERS < <(find "$WALL_DIR" "$STATIC_DIR" -type f \( \
        -iname '*.mp4' -o -iname '*.mkv' -o -iname '*.webm' -o \
        -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) | shuf)
    if [[ ${#WALLPAPERS[@]} -eq 0 ]]; then
        echo "$LOG_PREFIX ❌ No wallpapers found."
        exit 1
    fi
}

# --- MPV control ---
declare -A PIDS

start_wallpaper() {
    local monitor=$1
    local wall=$2
    echo "$LOG_PREFIX Launching mpvpaper on $monitor → $wall"
    mpvpaper "$monitor" "$wall" \
        -o "--no-audio --loop --fullscreen --no-osc --no-osd-bar \
            --geometry=100%x100% --script=$FADE_SCRIPT --script-opts=fade_duration=$FADE_DURATION --panscan=1" &
    PIDS["$monitor"]=$!
}

stop_wallpaper() {
    local monitor=$1
    [[ -n "${PIDS[$monitor]}" ]] && kill "${PIDS[$monitor]}" 2>/dev/null || true
    unset PIDS["$monitor"]
}

stop_all() {
    for monitor in "${!PIDS[@]}"; do
        stop_wallpaper "$monitor"
    done
}

# --- Fade helpers ---
fade_out_all() {
    for pid in "${PIDS[@]}"; do
        pkill -SIGUSR1 -P "$pid" 2>/dev/null || true
    done
}

fade_in_all() {
    for pid in "${PIDS[@]}"; do
        pkill -SIGUSR2 -P "$pid" 2>/dev/null || true
    done
}

# --- Power watcher ---
power_watcher() {
    echo "$LOG_PREFIX Starting power watcher..."
    # Detect AC adapter directory
    for acdir in /sys/class/power_supply/AC0 /sys/class/power_supply/AC /sys/class/power_supply/ADP1 /sys/class/power_supply/ACAD; do
        if [[ -d "$acdir" ]]; then
            AC_DIR="$acdir"
            break
        fi
    done

    if [[ -z "$AC_DIR" ]]; then
        echo "$LOG_PREFIX ⚠️ Could not find AC adapter directory. Battery pause may not work."
        return
    fi
    echo "$LOG_PREFIX ✅ Using AC adapter directory: $AC_DIR"

    LAST_STATE=""
    while true; do
        STATE_FILE="$AC_DIR/online"
        if [[ -f "$STATE_FILE" ]]; then
            CURRENT_STATE=$(cat "$STATE_FILE")
            if [[ "$CURRENT_STATE" != "$LAST_STATE" ]]; then
                if [[ "$CURRENT_STATE" == "1" ]]; then
                    echo "$LOG_PREFIX 🔌 On AC power — resuming wallpapers with fade"
                    fade_in_all
                    for pid in "${PIDS[@]}"; do kill -CONT "$pid" 2>/dev/null || true; done
                else
                    echo "$LOG_PREFIX 🔋 On battery — pausing wallpapers with fade"
                    fade_out_all
                    for pid in "${PIDS[@]}"; do kill -STOP "$pid" 2>/dev/null || true; done
                fi
                LAST_STATE="$CURRENT_STATE"
            fi
        fi
        sleep 5
    done
}

# --- Wallpaper rotation ---
rotate_wallpapers() {
    echo "$LOG_PREFIX Starting wallpaper rotation (every $((CHANGE_INTERVAL/60)) min)..."
    local index=0
    local total=${#WALLPAPERS[@]}

    while true; do
        local wall="${WALLPAPERS[$((index % total))]}"
        for monitor in $MONITORS; do
            stop_wallpaper "$monitor"
            start_wallpaper "$monitor" "$wall"
        done
        index=$((index + 1))
        sleep "$CHANGE_INTERVAL"
    done
}

# --- Start script ---
stop_all
build_playlist
power_watcher &
rotate_wallpapers
