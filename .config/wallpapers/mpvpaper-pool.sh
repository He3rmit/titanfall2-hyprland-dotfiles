#!/usr/bin/env bash
# mpvpaper-pool.sh - Robust, event-driven multi-monitor wallpaper manager
# Place in ~/.config/hypr/scripts/, chmod +x, add to hyprland.conf exec-once

set -euo pipefail
IFS=$'\n\t'

log() { echo "[$(date +'%H:%M:%S')] $*"; }

### ---------- CONFIG ----------
WALL_DIR="$HOME/.config/wallpapers/wallpaper-samples"
STATIC_DIR="$HOME/.config/wallpapers/static"
TMP_DIR="${XDG_RUNTIME_DIR:-/tmp}/mpvpaper-pool"
mkdir -p "$TMP_DIR"

INTERVAL=600  # seconds between playlist items
MPV_OPTS="--no-audio --loop --hwdec=auto-safe --really-quiet --no-terminal --geometry=100%x100%"
FADE_SCRIPT="$HOME/.config/wallpapers/fade.lua"
CHECK_AC_WITH_UPOWER=true
BATTERY_THRESHOLD=20  # below this % -> static fallback

# Runtime/Wayland defaults
export XDG_RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
export WAYLAND_DISPLAY="${WAYLAND_DISPLAY:-wayland-1}"

### ---------- STATE ----------
declare -A PID      # mpvpaper pid per monitor
declare -A MODE     # "video"|"static"
declare -A PLAYLIST # playlist file per monitor
declare -A SOCK     # per-monitor IPC socket

### ---------- POWER HELPERS ----------
on_ac() {
    if $CHECK_AC_WITH_UPOWER && command -v upower >/dev/null 2>&1; then
        upower -i "$(upower -e | grep -E 'AC|line' | head -n1 2>/dev/null)" \
            | grep -Eq "online: *yes|state: *charging|state: *fully-charged"
    else
        [[ -f /sys/class/power_supply/AC/online ]] && [[ "$(cat /sys/class/power_supply/AC/online)" == "1" ]]
    fi
}

battery_pct() {
    if $CHECK_AC_WITH_UPOWER && command -v upower >/dev/null 2>&1; then
        upower -i "$(upower -e | grep -E 'BAT' | head -n1)" \
            | awk -F: '/percentage/ {gsub(/ /,"",$2); gsub(/%/,"",$2); print $2; exit}'
    else
        cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -n1 || echo 100
    fi
}

### ---------- FILE HELPERS ----------
pick_random_from_pool() {
    find "$WALL_DIR" -type f \( -iname "*.mp4" -o -iname "*.webm" -o -iname "*.mkv" -o -iname "*.gif" -o -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" \) 2>/dev/null | shuf -n 1
}

build_playlist() {
    local mon="$1"
    local plist="$TMP_DIR/playlist-${mon}.txt"
    find "$WALL_DIR" -type f \( -iname "*.mp4" -o -iname "*.webm" -o -iname "*.mkv" -o -iname "*.gif" -o -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" \) 2>/dev/null | shuf > "$plist"
    echo "$plist"
}

pick_static_for_monitor() {
    local mon="$1"
    if [[ -d "$STATIC_DIR" ]]; then
        if [[ -f "$STATIC_DIR/${mon}.png" ]]; then echo "$STATIC_DIR/${mon}.png" && return; fi
        if [[ -f "$STATIC_DIR/${mon}.jpg" ]]; then echo "$STATIC_DIR/${mon}.jpg" && return; fi
        find "$STATIC_DIR" -maxdepth 1 -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" \) 2>/dev/null | shuf -n 1
    else
        find "$WALL_DIR" -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" \) 2>/dev/null | shuf -n 1
    fi
}

get_monitors() {
    hyprctl monitors -j 2>/dev/null | jq -r '.[].name' 2>/dev/null || true
}

send_fade() {
    local mon="$1" action="$2"
    local sock="${SOCK[$mon]:-}"
    [[ -S "$sock" ]] || return
    printf '%s\n' '{"command":["script-message","'"$action"'"]}' | socat - UNIX-CONNECT:"$sock" 2>/dev/null || true
}

### ---------- MPV PAPER CONTROL ----------
start_monitor() {
    local mon="$1"
    log "start_monitor: $mon"
    stop_monitor "$mon" >/dev/null 2>&1 || true

    local plist
    plist="$(build_playlist "$mon")"
    PLAYLIST[$mon]="$plist"

    local sock="$TMP_DIR/mpv-${mon}.sock"
    SOCK[$mon]="$sock"
    [[ -e "$sock" ]] && rm -f "$sock"

    local mpv_opts="$MPV_OPTS --image-display-duration=$INTERVAL"
    [[ -f "$FADE_SCRIPT" ]] && mpv_opts="$mpv_opts --script=$FADE_SCRIPT"

    mpvpaper -n "$INTERVAL" -o "$mpv_opts" "$mon" --playlist="$plist" >/dev/null 2>&1 &
    PID[$mon]=$!
    MODE[$mon]="video"
    log "launched mpvpaper on $mon (pid ${PID[$mon]})"
}

stop_monitor() {
    local mon="$1"
    log "stop_monitor: $mon"
    [[ -n "${PID[$mon]:-}" ]] && kill "${PID[$mon]}" 2>/dev/null || pkill -f "mpvpaper.*$mon" 2>/dev/null || true
    [[ -n "${PLAYLIST[$mon]:-}" ]] && rm -f "${PLAYLIST[$mon]}" 2>/dev/null || true
    [[ -n "${SOCK[$mon]:-}" ]] && rm -f "${SOCK[$mon]}" 2>/dev/null || true
    unset PID[$mon] MODE[$mon] PLAYLIST[$mon] SOCK[$mon]
}

switch_monitor_to_static() {
    local mon="$1"
    log "switch_monitor_to_static: $mon"
    stop_monitor "$mon" >/dev/null 2>&1
    local staticfile
    staticfile="$(pick_static_for_monitor "$mon")"
    [[ -z "$staticfile" ]] && { log "no static for $mon"; return; }
    mpvpaper -o "--no-audio --image-display-duration=inf --no-terminal --really-quiet --geometry=100%x100%" "$mon" "$staticfile" >/dev/null 2>&1 &
    PID[$mon]=$!
    MODE[$mon]="static"
    log "static running on $mon (pid ${PID[$mon]})"
}

pause_monitor() {
    local mon="$1"
    if [[ -n "${PID[$mon]:-}" ]]; then
        log "pause_monitor: $mon"
        send_fade "$mon" "fade_out"
        sleep 0.2
        kill -STOP "${PID[$mon]}" 2>/dev/null || true
    fi
}

resume_monitor() {
    local mon="$1"
    if [[ -n "${PID[$mon]:-}" ]]; then
        log "resume_monitor: $mon"
        kill -CONT "${PID[$mon]}" 2>/dev/null || true
        sleep 0.15
        send_fade "$mon" "fade_in"
    elif on_ac; then
        start_monitor "$mon"
    fi
}

sync_monitors() {
    local monitors
    mapfile -t monitors < <(get_monitors)
    declare -A present
    for m in "${monitors[@]}"; do present[$m]=1; done

    for m in "${monitors[@]}"; do [[ -z "${PID[$m]:-}" ]] && start_monitor "$m"; done
    for m in "${!PID[@]}"; do [[ -z "${present[$m]:-}" ]] && stop_monitor "$m"; done
}

### ---------- EVENTS ----------
handle_event_line() {
    local line="$1"

    case "$line" in
        workspace\>*)
            local ws
            ws="$(hyprctl activeworkspace -j | jq -r '.name' || echo "")"
            if [[ "$ws" == special* ]]; then
                for mon in "${!PID[@]}"; do pause_monitor "$mon"; done
            else
                for mon in "${!PID[@]}"; do resume_monitor "$mon"; done
            fi
            ;;
        activewindow\>*)
            local addr="${line#activewindow>>}"
            if [[ "$addr" == "0x0" || "$addr" == "0" ]]; then
                for mon in "${!PID[@]}"; do resume_monitor "$mon"; done
            else
                for mon in "${!PID[@]}"; do pause_monitor "$mon"; done
            fi
            ;;
        monitor\>*add*|monitor\>*remove*)
            sync_monitors
            ;;
    esac
}

### ---------- CLEANUP ----------
cleanup() {
    log "cleanup: stopping monitors"
    for m in "${!PID[@]}"; do stop_monitor "$m"; done
    rm -rf "$TMP_DIR"
}
trap cleanup EXIT

### ---------- STARTUP ----------
if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
    log "HYPRLAND_INSTANCE_SIGNATURE missing! Launch after Hyprland."
    exit 1
fi
HYPR_SOCKET="$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock"
while [[ ! -S "$HYPR_SOCKET" ]]; do sleep 0.2; done
log "Using Hypr socket: $HYPR_SOCKET"

### ---------- MAIN ----------
main() {
    log "mpvpaper-pool starting"
    sync_monitors

    # battery fallback at startup
    if ! on_ac; then
        for mon in "${!PID[@]}"; do switch_monitor_to_static "$mon"; done
    fi

    # event listener
    socat - UNIX-CONNECT:"$HYPR_SOCKET" 2>/dev/null | while read -r line; do
        handle_event_line "$line"
    done &
    LISTENER_PID=$!

    # keep parent alive so mpvpaper children persist
    while kill -0 "$LISTENER_PID" 2>/dev/null; do sleep 10; done
}

main
