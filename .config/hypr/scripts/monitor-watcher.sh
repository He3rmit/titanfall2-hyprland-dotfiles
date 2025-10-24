#!/usr/bin/env bash
while true; do
    inotifywait -e modify /sys/class/drm/*/status
    ~/.config/hypr/mirror-monitors.sh
done
