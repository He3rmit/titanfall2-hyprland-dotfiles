#!/usr/bin/env bash
# ───────────────────────────────────────────────
# mpvpaper-pool.sh — Mark 3 (Kill Switch + Fullscreen Fix)
# ───────────────────────────────────────────────

LOG_PREFIX="[mpvpaper-pool]"
WALL_DIR="$HOME/.config/wallpapers/wallpaper-samples"
STATIC_DIR="$HOME/.config/wallpapers/static"
CHANGE_INTERVAL=$((20 * 60))   # 20 minutes
FADE_SCRIPT="$HOME/.config/wallpapers/fade.lua"
FADE_DURATION=1.0

# --- Setup ---
export XDG_RUNTIME_DIR="/run/user/$(id -u)"
PIDS_FILE="/tmp/mpvpaper_pids"

# --- 1. Identify Media Types ---
get_random_video() {
    find "$WALL_DIR" "$STATIC_DIR" -type f \( -iname '*.mp4' -o -iname '*.mkv' -o -iname '*.webm' \) 2>/dev/null | shuf -n 1
}

get_random_image() {
    find "$WALL_DIR" "$STATIC_DIR" -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) 2>/dev/null | shuf -n 1
}

# --- 2. The Launcher ---
apply_wallpaper() {
    local mode=$1 # "video" or "static"
    local monitors=$(hyprctl monitors -j | jq -r '.[].name')
    
    echo "$LOG_PREFIX 🔄 Switching Mode: $mode"

    # Kill old instances immediately
    pkill mpvpaper 2>/dev/null
    sleep 0.5

    for monitor in $monitors; do
        if [[ "$mode" == "video" ]]; then
            # AC POWER: Load Video
            local wall=$(get_random_video)
            [[ -z "$wall" ]] && wall=$(get_random_image)
            
            echo "$LOG_PREFIX 🔌 AC: Launching Video on $monitor -> $(basename "$wall")"
            
            # FIX: Added --panscan=1.0 to force fill the screen
            mpvpaper "$monitor" "$wall" \
                -o "--no-audio --loop --fullscreen --panscan=1.0 --no-osc --no-osd-bar \
                    --geometry=100%x100% --script=$FADE_SCRIPT --script-opts=fade_duration=$FADE_DURATION" &
        else
            # BATTERY POWER: Load Static Image
            local wall=$(get_random_image)
            echo "$LOG_PREFIX 🔋 Batt: Launching Static on $monitor -> $(basename "$wall")"
            
            # FIX: Added --panscan=1.0 here too
            mpvpaper "$monitor" "$wall" \
                -o "--loop-file=inf --fullscreen --panscan=1.0 --no-osc --no-osd-bar --geometry=100%x100%" &
        fi
    done
}

# --- 3. Power Monitor Loop ---
monitor_power() {
    # Find AC Adapter
    local AC_FILE=""
    for ac in /sys/class/power_supply/AC* /sys/class/power_supply/ADP* /sys/class/power_supply/ACAD*; do
        if [[ -f "$ac/online" ]]; then AC_FILE="$ac/online"; break; fi
    done

    local last_state="-1"
    local counter=0
    local rotation_limit=$((CHANGE_INTERVAL / 5)) # Convert 20mins to 5s ticks

    while true; do
        # Read Power State
        local current_state=1
        if [[ -f "$AC_FILE" ]]; then
            current_state=$(cat "$AC_FILE")
        fi

        # CHECK 1: Power Source Change?
        if [[ "$current_state" != "$last_state" ]]; then
            if [[ "$current_state" == "1" ]]; then
                apply_wallpaper "video"
            else
                apply_wallpaper "static"
            fi
            last_state="$current_state"
            counter=0 
        fi

        # CHECK 2: Rotation Timer?
        if [[ "$counter" -ge "$rotation_limit" ]]; then
            echo "$LOG_PREFIX ⏰ Rotation Timer Hit"
            if [[ "$current_state" == "1" ]]; then
                apply_wallpaper "video"
            else
                apply_wallpaper "static"
            fi
            counter=0
        fi

        sleep 5
        ((counter++))
    done
}

# --- Execute ---
monitor_power