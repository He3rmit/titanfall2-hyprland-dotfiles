#!/bin/bash

WALLPAPERS=(
    "/home/rex/dotfiles/.config/wallpapers/wallpaper-samples/jack-cooper-bt-7274-titanfall-2-moewalls-com.mp4"
    "/home/rex/dotfiles/.config/wallpapers/wallpaper-samples/pulse-blade-pilot-titanfall-2-moewalls-com.mp4"
    "/home/rex/dotfiles/.config/wallpapers/wallpaper-samples/titanfall-2-moewalls-com.mp4"
)

WALLPAPERS=($(shuf -e "${WALLPAPERS[@]}"))


while true; do
    for w in "${WALLPAPERS[@]}"; do
        # Kill any running mpvpaper
        pkill -f "mpvpaper"

        # Start new wallpaper
        mpvpaper --loop --scale=cover "$w" &

        # Wait for video duration or desired interval (e.g., 60s)
        sleep 3600
    done
done
