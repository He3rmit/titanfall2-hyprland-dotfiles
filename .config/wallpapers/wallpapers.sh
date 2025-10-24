#!/bin/bash

MONITOR="eDP-1"  # change this to your actual monitor name (use `hyprctl monitors` to check)

WALLPAPERS=(
    "/home/rex/dotfiles/.config/wallpapers/wallpaper-samples/jack-cooper-bt-7274-titanfall-2-moewalls-com.mp4"
    "/home/rex/dotfiles/.config/wallpapers/wallpaper-samples/pulse-blade-pilot-titanfall-2-moewalls-com.mp4"
    "/home/rex/dotfiles/.config/wallpapers/wallpaper-samples/titanfall-2-moewalls-com.mp4"
)

while true; do
    # Shuffle the wallpaper order each cycle
    SHUFFLED=($(shuf -e "${WALLPAPERS[@]}"))

    for w in "${SHUFFLED[@]}"; do
        echo "Now playing: $w"

        # Kill any existing mpvpaper process
        pkill -f "mpvpaper"

        # Start mpvpaper with full-screen fit and GPU acceleration
        mpvpaper -o "no-audio loop --hwdec=auto --panscan=1.0 --geometry=100%x100%" "$MONITOR" "$w" &

        # Duration to display each wallpaper (e.g. 60s = 1 minute, 3600 = 1 hour)
        sleep 1800
    done
done

