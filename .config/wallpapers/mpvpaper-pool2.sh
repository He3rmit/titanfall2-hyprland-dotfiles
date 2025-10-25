#!/usr/bin/env bash
# mpvpaper-event.sh
# Event-driven, multi-monitor, battery-aware wallpaper manager for Hyprland using mpvpaper
# Place: ~/.config/hypr/scripts/mpvpaper-event.sh
# Make executable: chmod +x ~/.config/hypr/scripts/mpvpaper-event.sh
# Requirements: mpvpaper, mpv, jq, socat, upower (optional)

set -euo pipefail
IFS=$'\n\t'

### ========== CONFIG ==========
WALL_DIR="$HOME/.config/wallpapers/wallpaper-samples"   # pool (mixed images + videos)
STATIC_DIR="$HOME/.config/wallpapers/static"            # optional per-monitor static files (optional)
TMP_DIR="${XDG_RUNTIME_DIR:-/tmp}/mpvpaper-event"
mkdir -p "$TMP_DIR"

INTERVAL=600                   # seconds between playlist items (mpvpaper -n)
MPV_COMMON_OPTS="--no-audio --loop --hwdec=auto-safe --vo=gpu-next --really-quiet --no-terminal"
FADE_SCRIPT="$HOME/.config/wallpapers/fade.lua"        # fade.lua path
CHECK_AC_WITH_UPOWER=true
BATTERY_THRESHOLD=20           # percent threshold (if you want threshold logic)

# CLI control (pause/resume/reload/toggle)
if [[ "${1:-}" == "pause" ]]; then
  pkill -STOP -f mpvpaper || true
  echo "Paused wallpapers."
  exit 0
fi
if [[ "${1:-}" == "resume" ]]; then
  pkill -CONT -f mpvpaper || true
  echo "Resumed wallpapers."
  exit 0
fi
if [[ "${1:-}" == "reload" ]]; then
  pkill -f mpvpaper || true
  sleep 1
  exec "$0" &
  exit 0
fi
if [[ "${1:-}" == "toggle" ]]; then
  if pgrep -x mpvpaper >/dev/null; then
    pkill -STOP -f mpvpaper && echo "Wallpapers paused." || true
  else
    pkill -CONT -f mpvpaper && echo "Wallpapers resumed." || true
  fi
  exit 0
fi

log() { echo "[$(date '+%H:%M:%S')] $*"; }

### ========== ENV / SOCKET AUTO-DETECT ==========
# Wait until Hyprland socket exists (robust startup)
wait_for_socket() {
  local attempts=0
  while true; do
    HYPRLAND_INSTANCE_SIGNATURE="${HYPRLAND_INSTANCE_SIGNATURE:-$(ls /run/user/$UID/hypr 2>/dev/null | head -n1 || true)}"
    HYPRLAND_SOCKET="/run/user/$UID/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"
    if [[ -S "$HYPRLAND_SOCKET" ]]; then
      export HYPRLAND_INSTANCE_SIGNATURE HYPRLAND_SOCKET
      log "Using Hyprland socket: $HYPRLAND_SOCKET"
      break
    fi
    # also try .socket.sock as fallback
    if [[ -S "/run/user/$UID/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket.sock" ]]; then
      HYPRLAND_SOCKET="/run/user/$UID/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket.sock"
      export HYPRLAND_INSTANCE_SIGNATURE HYPRLAND_SOCKET
      log "Using Hyprland socket (fallback): $HYPRLAND_SOCKET"
      break
    fi
    attempts=$((attempts+1))
    if (( attempts % 5 == 0 )); then
      log "Waiting for Hyprland socket (still)..."
    fi
    sleep 1
  done
}
wait_for_socket

### ========== SANITY CHECKS ==========
if [[ ! -d "$WALL_DIR" ]]; then
  log "ERROR: wallpaper directory missing: $WALL_DIR"
  exit 1
fi

if ! find "$WALL_DIR" -type f \( -iname "*.mp4" -o -iname "*.webm" -o -iname "*.mkv" -o -iname "*.jpg" -o -iname "*.png" \) | grep -q .; then
  log "ERROR: no wallpapers found in $WALL_DIR"
  exit 1
fi

### ========== STATE ==========
declare -A PIDS      # mpvpaper pid per monitor
declare -A MODE      # "video" | "static" per monitor
declare -A PLAYLIST  # playlist file path per monitor
declare -A SOCKPATH  # mpv ipc socket per monitor

cleanup() {
  log "cleanup: stopping wallpapers..."
  for m in "${!PIDS[@]}"; do
    kill "${PIDS[$m]}" 2>/dev/null || true
  done
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

### ========== POWER HELPERS ==========
on_ac() {
  if $CHECK_AC_WITH_UPOWER && command -v upower >/dev/null 2>&1; then
    upower -i "$(upower -e | grep -E 'AC|line' | head -n1 2>/dev/null)" 2>/dev/null \
      | grep -Eq "online: *yes|state: *charging|state: *fully-charged" && return 0 || return 1
  else
    if [[ -e /sys/class/power_supply/AC/online ]]; then
      [[ "$(cat /sys/class/power_supply/AC/online 2>/dev/null)" == "1" ]] && return 0 || return 1
    elif [[ -e /sys/class/power_supply/ACAD/online ]]; then
      [[ "$(cat /sys/class/power_supply/ACAD/online 2>/dev/null)" == "1" ]] && return 0 || return 1
    else
      return 0
    fi
  fi
}

battery_pct() {
  if $CHECK_AC_WITH_UPOWER && command -v upower >/dev/null 2>&1; then
    upower -i "$(upower -e | grep -E 'BAT' | head -n1)" 2>/dev/null | awk -F: '/percentage/ {gsub(/ /,"",$2); gsub(/%/,"",$2); print $2; exit}'
  else
    cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -n1 || echo 100
  fi
}

### ========== PLAYLIST & FILE HELPERS ==========
# Build playlist file containing shuffled items from pool
build_playlist() {
  local mon="$1"
  local file="$TMP_DIR/playlist-${mon}.txt"
  find "$WALL_DIR" -type f \( -iname "*.mp4" -o -iname "*.webm" -o -iname "*.mkv" -o -iname "*.gif" -o -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" \) 2>/dev/null | shuf > "$file"
  echo "$file"
}

pick_static_for_monitor() {
  local mon="$1"
  # prefer specific static named after monitor, else pick any image file
  if [[ -d "$STATIC_DIR" ]]; then
    if [[ -f "$STATIC_DIR/${mon}.png" ]]; then echo "$STATIC_DIR/${mon}.png" && return; fi
    if [[ -f "$STATIC_DIR/${mon}.jpg" ]]; then echo "$STATIC_DIR/${mon}.jpg" && return; fi
    find "$STATIC_DIR" -maxdepth 1 -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" \) 2>/dev/null | shuf -n 1
  fi
  find "$WALL_DIR" -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" \) 2>/dev/null | shuf -n 1
}

get_monitors() {
  hyprctl monitors -j 2>/dev/null | jq -r '.[].name' 2>/dev/null || true
}

# send fade command to mpv ipc socket
send_fade() {
  local mon="$1"
  local action="$2" # fade_in or fade_out
  if [[ -n "${SOCKPATH[$mon]:-}" && -S "${SOCKPATH[$mon]}" ]]; then
    printf '%s\n' "{\"command\": [\"script-message\", \"${action}\"]}" | socat - UNIX-CONNECT:"${SOCKPATH[$mon]}" 2>/dev/null || true
  fi
}

### ========== MPV/MPVPAper LAUNCH/CONTROL ==========
start_monitor() {
  local mon="$1"
  log "start_monitor: $mon"
  stop_monitor "$mon" >/dev/null 2>&1 || true

  local plist
  plist=$(build_playlist "$mon")
  if [[ ! -s "$plist" ]]; then
    log "ERROR: playlist for $mon is empty (no files in $WALL_DIR)"
    return 1
  fi
  PLAYLIST[$mon]="$plist"

  local sock="$TMP_DIR/mpv-${mon}.sock"
  SOCKPATH[$mon]="$sock"
  [[ -e "$sock" ]] && rm -f "$sock"

  local mpv_opts="$MPV_COMMON_OPTS --script=${FADE_SCRIPT} --input-ipc-server=${sock} --image-display-duration=${INTERVAL}"
  # mpvpaper -n <seconds> -o "<mpv options>" <monitor> --playlist=<file>
  mpvpaper -n "$INTERVAL" -o "$mpv_opts" "$mon" --playlist="$plist" >/dev/null 2>&1 &
  PIDS[$mon]=$!
  MODE[$mon]="video"
  log "launched mpvpaper on $mon (pid ${PIDS[$mon]})"
  return 0
}

stop_monitor() {
  local mon="$1"
  log "stop_monitor: $mon"
  if [[ -n "${PIDS[$mon]:-}" ]]; then
    kill "${PIDS[$mon]}" 2>/dev/null || true
    unset PIDS[$mon]
  else
    pkill -f "mpvpaper.*$mon" 2>/dev/null || true
  fi
  [[ -n "${PLAYLIST[$mon]:-}" ]] && rm -f "${PLAYLIST[$mon]}" 2>/dev/null || true
  [[ -n "${SOCKPATH[$mon]:-}" ]] && rm -f "${SOCKPATH[$mon]}" 2>/dev/null || true
  unset MODE[$mon]
  unset PLAYLIST[$mon]
  unset SOCKPATH[$mon]
}

switch_monitor_to_static() {
  local mon="$1"
  log "switch_monitor_to_static: $mon"
  stop_monitor "$mon" >/dev/null 2>&1 || true
  local staticfile
  staticfile=$(pick_static_for_monitor "$mon")
  if [[ -z "$staticfile" ]]; then
    log "no static file found for $mon"
    return 1
  fi
  mpvpaper -o "--no-audio --image-display-duration=inf --no-terminal --really-quiet --geometry=100%x100%" "$mon" "$staticfile" >/dev/null 2>&1 &
  PIDS[$mon]=$!
  MODE[$mon]="static"
  log "static running on $mon (pid ${PIDS[$mon]})"
  return 0
}

pause_monitor() {
  local mon="$1"
  if [[ -n "${PIDS[$mon]:-}" ]]; then
    log "pause_monitor: $mon"
    send_fade "$mon" "fade_out"
    sleep 0.25
    kill -STOP "${PIDS[$mon]}" 2>/dev/null || true
  else
    pkill -STOP -f "mpvpaper.*$mon" 2>/dev/null || true
  fi
}

resume_monitor() {
  local mon="$1"
  if [[ -n "${PIDS[$mon]:-}" ]]; then
    log "resume_monitor: $mon"
    kill -CONT "${PIDS[$mon]}" 2>/dev/null || true
    sleep 0.15
    send_fade "$mon" "fade_in"
  else
    # monitor has no process, (re)start it if on AC
    if on_ac; then
      start_monitor "$mon" || true
    fi
  fi
}

sync_monitors() {
  local monlist=()
  mapfile -t monlist < <(get_monitors)
  declare -A present=()
  for m in "${monlist[@]}"; do present[$m]=1; done

  # start missing
  for m in "${monlist[@]}"; do
    if [[ -z "${PIDS[$m]:-}" ]]; then
      start_monitor "$m"
    fi
  done

  # stop removed
  for m in "${!PIDS[@]}"; do
    if [[ -z "${present[$m]:-}" ]]; then
      stop_monitor "$m"
    fi
  done
}

### ========== HYPR EVENT HANDLING ==========
handle_line() {
  local line="$1"
  # workspace special overlay
  if [[ "$line" == workspace\>*special* ]]; then
    log "event: special workspace -> pause all"
    for mon in "${!PIDS[@]}"; do pause_monitor "$mon"; done
    return
  fi

  if [[ "$line" == workspace\>* ]]; then
    local ws
    ws=$(hyprctl activeworkspace -j 2>/dev/null | jq -r '.name' 2>/dev/null || echo "")
    if [[ "$ws" == special* ]]; then
      log "workspace changed to special ($ws) -> pause"
      for mon in "${!PIDS[@]}"; do pause_monitor "$mon"; done
    else
      log "workspace changed to $ws -> maybe resume"
      if on_ac && [[ "$(hyprctl activewindow -j 2>/dev/null | jq -r '.address')" == "0x0" ]]; then
        for mon in "${!PIDS[@]}"; do resume_monitor "$mon"; done
      fi
    fi
    return
  fi

  if [[ "$line" == activewindow\>* ]]; then
    local addr="${line#activewindow>>}"
    if [[ "$addr" == "0x0" || "$addr" == "0" ]]; then
      log "event: no focused window -> resume (if AC)"
      if on_ac; then
        for mon in "${!PIDS[@]}"; do resume_monitor "$mon"; done
      fi
    else
      log "event: window focused ($addr) -> pause"
      for mon in "${!PIDS[@]}"; do pause_monitor "$mon"; done
    fi
    return
  fi

  if [[ "$line" == monitor\>*add* || "$line" == monitor\>*remove* ]]; then
    log "event: monitor hotplug -> sync"
    sync_monitors
    return
  fi
}

### ========== MAIN LOOP ==========
log "mpvpaper-event starting"
sync_monitors

# initial battery handling: if on battery -> static
if ! on_ac; then
  log "on battery at startup -> switch all monitors to static"
  for mon in "${!PIDS[@]}"; do switch_monitor_to_static "$mon"; done
fi

# Read hypr events (event-driven)
socat - UNIX-CONNECT:"$HYPRLAND_SOCKET" 2>/dev/null | while read -r line; do
  # react to AC changes frequently (cheap) -- switch between static/video on plug/unplug
  if on_ac; then
    # ensure monitors are in video mode
    for mon in "${!PIDS[@]}"; do
      if [[ "${MODE[$mon]:-}" != "video" ]]; then
        stop_monitor "$mon" >/dev/null 2>&1 || true
        start_monitor "$mon"
      fi
    done
  else
    # on battery -> switch to static if not already
    for mon in "${!PIDS[@]}"; do
      if [[ "${MODE[$mon]:-}" != "static" ]]; then
        switch_monitor_to_static "$mon"
      fi
    done
  fi

  handle_line "$line"
done
