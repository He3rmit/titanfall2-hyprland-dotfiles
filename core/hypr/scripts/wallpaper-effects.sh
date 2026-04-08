#!/usr/bin/env bash

# Fetch exactly what is playing
CURRENT_WALLPAPER_FILE="$HOME/.config/wallpapers/.current_wallpaper"
if [[ ! -f "$CURRENT_WALLPAPER_FILE" ]]; then
    exit 1
fi

selected_path=$(cat "$CURRENT_WALLPAPER_FILE")

# If it's a video, ignore (or show notification)
if [[ "$selected_path" =~ \.(mp4|webm|mkv)$ ]]; then
    notify-send -u normal "Wallpaper Effects" "Effects are not supported on video wallpapers."
    exit 0
fi

CACHE_DIR="$HOME/.cache/wallpaper-thumbnails"
mkdir -p "$CACHE_DIR"

# If it is an image, prompt the Effects Menu
EFFECTS="Original\nBlur\nGrayscale\nNoir Blur\nBT-7274 Camo\nCyber Tint\nSynthwave\nSepia / Rust\nNeon Outline\nPixelate\nGlitch\nCRT Scanlines\nOil Paint\nCharcoal Sketch\nHalftone\nVignette"
selected_effect=$(echo -e "$EFFECTS" | rofi -dmenu -i -p "󰸉 Effect" -theme "$HOME/.config/rofi/themes/runner.rasi")

if [[ -z "$selected_effect" ]]; then
    exit 0
fi

if [[ "$selected_effect" == "Original" ]]; then
    ~/.config/hypr/scripts/wallpaper-selector.sh --set "$selected_path"
    exit 0
fi

notify-send -t 3000 -h string:x-canonical-private-synchronous:sys-notify -u normal "Wallpaper Engine" "Processing: $selected_effect..."

TIMESTAMP=$(date +%s)
EFFECT_FILE="$CACHE_DIR/current_wallpaper_effect_${TIMESTAMP}.jpg"

# Clean up old effects to prevent cache bloat
rm -f "$CACHE_DIR"/current_wallpaper_effect_*.jpg 2>/dev/null

case "$selected_effect" in
    "Blur")
        magick "$selected_path" -blur 0x16 "$EFFECT_FILE"
        ;;
    "Grayscale")
        magick "$selected_path" -colorspace gray "$EFFECT_FILE"
        ;;
    "Noir Blur")
        magick "$selected_path" -colorspace gray -blur 0x16 "$EFFECT_FILE"
        ;;
    "BT-7274 Camo")
        # Vanguard Forest Green (#1A2F1A) & Militia Orange (#E55A00)
        magick "$selected_path" -colorspace gray +level-colors "#1A2F1A","#E55A00" "$EFFECT_FILE"
        ;;
    "Cyber Tint")
        # Deep Sea Cyan/Dark Blue (#001A22) & Terminal Cyan (#00E0FF)
        magick "$selected_path" -colorspace gray +level-colors "#001A22","#00E0FF" "$EFFECT_FILE"
        ;;
    "Synthwave")
        # Deep Purple (#1B032A) & Neon Pink (#FF00B3)
        magick "$selected_path" -colorspace gray +level-colors "#1B032A","#FF00B3" "$EFFECT_FILE"
        ;;
    "Sepia / Rust")
        magick "$selected_path" -sepia-tone 80% "$EFFECT_FILE"
        ;;
    "Neon Outline")
        magick "$selected_path" -colorspace gray -edge 2 -negate -normalize -colorspace sRGB +level-colors "#000000","#00FFCC" "$EFFECT_FILE"
        ;;
    "Pixelate")
        magick "$selected_path" -scale 5% -scale 2000% "$EFFECT_FILE"
        ;;
    "Glitch")
        # Chromatic aberration (Channel offset by 15 pixels)
        magick "$selected_path" \
            \( -clone 0 -channel R -separate -roll +15+0 \) \
            \( -clone 0 -channel G -separate \) \
            \( -clone 0 -channel B -separate -roll -15+0 \) \
            -channel RGB -combine "$EFFECT_FILE"
        ;;
    "CRT Scanlines")
        # Terminal green tint + horizontal scanlines overlay
        magick "$selected_path" -colorspace gray +level-colors "#001500","#00FF33" \
            \( -size 1x4 pattern:horizontal2 -scale 4000x4000 \) \
            -compose multiply -composite "$EFFECT_FILE"
        ;;
    "Oil Paint")
        magick "$selected_path" -paint 4 "$EFFECT_FILE"
        ;;
    "Charcoal Sketch")
        magick "$selected_path" -colorspace gray -charcoal 2 "$EFFECT_FILE"
        ;;
    "Halftone")
        magick "$selected_path" -ordered-dither h8x8o "$EFFECT_FILE"
        ;;
    "Vignette")
        magick "$selected_path" -background black -vignette 0x60 "$EFFECT_FILE"
        ;;
esac

echo "$EFFECT_FILE" > "$HOME/.config/wallpapers/.current_effect_image"
~/.config/hypr/scripts/wallpaper-selector.sh --set "$EFFECT_FILE"
