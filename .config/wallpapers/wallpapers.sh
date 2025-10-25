#!/bin/bash

MONITOR="eDP-1"  # change this to your actual monitor name (use `hyprctl monitors` to check)

WALLPAPERS=(
    "/home/rex/dotfiles/.config/wallpapers/wallpaper-samples/jack-cooper-bt-7274-titanfall-2-moewalls-com.mp4"
    "/home/rex/dotfiles/.config/wallpapers/wallpaper-samples/pulse-blade-pilot-titanfall-2-moewalls-com.mp4"
    "/home/rex/dotfiles/.config/wallpapers/wallpaper-samples/titanfall-2-moewalls-com.mp4"
    "/home/rex/dotfiles/.config/wallpapers/wallpaper-samples/1654597346-1654597346-pc-titanfall-2-titans-live-wallpaper.mp4"
    "/home/rex/dotfiles/.config/wallpapers/wallpaper-samples/1654600368-1654600368-pc-titanfall-2-teamates-live-wallpaper.mp4"
    "/home/rex/dotfiles/.config/wallpapers/wallpaper-samples/1654601277-1654601277-pc-titanfall-2-helmet-live-wallpaper.mp4"
    "/home/rex/dotfiles/.config/wallpapers/wallpaper-samples/1675814147-1675814147-bt-7274-titanfall-2-live-wallpaper.mp4"
    "/home/rex/dotfiles/.config/wallpapers/wallpaper-samples/1677584455-1677584455-titanfall-2-ue.mp4"
    "/home/rex/dotfiles/.config/wallpapers/wallpaper-samples/1687451191-1687451191-pulse-blade-titanfall-4k-live-wallpaper.mp4"
)

while true; do
    # Shuffle the wallpaper order each cycle
    SHUFFLED=($(shuf -e "${WALLPAPERS[@]}"))

    for w in "${SHUFFLED[@]}"; do
        echo "Now playing: $w"

        # Kill any existing mpvpaper processz
        pkill -f "mpvpaper"

        # Start mpvpaper with full-screen fit and GPU acceleration
        mpvpaper -s -o "no-audio loop --hwdec=auto --panscan=1.0 --geometry=100%x100%" "$MONITOR" "$w" &

        # Duration to display each wallpaper (e.g. 60s = 1 minute, 3600 = 1 hour)
        sleep 1800
    done
done

