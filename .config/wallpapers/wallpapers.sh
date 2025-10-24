#!/bin/bash

WALLPAPERS=(
    "/home/username/Videos/wallpaper1.mp4"
    "/home/username/Videos/wallpaper2.mp4"
    "/home/username/Videos/wallpaper3.mp4"
)

while true; do
    for w in "${WALLPAPERS[@]}"; do
        # Kill any running mpvpaper
        pkill -f "mpvpaper"

        # Start new wallpaper
        mpvpaper --loop --scale=cover "$w" &

        # Wait for video duration or desired interval (e.g., 60s)
        sleep 60
    done
done

