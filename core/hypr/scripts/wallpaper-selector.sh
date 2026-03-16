#!/usr/bin/env bash

WALL_DIR="$HOME/.config/wallpapers/library"
CURRENT_WALLPAPER_FILE="$HOME/.config/wallpapers/.current_wallpaper"

apply_wallpaper() {
    local wall="$1"
    if [[ -z "$wall" || ! -f "$wall" ]]; then
        return
    fi
    
    # Save current wallpaper
    echo "$wall" > "$CURRENT_WALLPAPER_FILE"
    
    local monitors=$(hyprctl monitors -j | jq -r '.[].name')
    
    # Kill existing mpvpaper instances
    pkill mpvpaper 2>/dev/null
    sleep 0.5
    
    # Determine type
    local is_video=0
    if [[ "$wall" =~ \.(mp4|webm|mkv)$ ]]; then
        is_video=1
    fi
    
    for monitor in $monitors; do
        if [[ $is_video -eq 1 ]]; then
            # Video settings (using existing fade script if it exists)
            local fade_opt=""
            if [[ -f "$HOME/.config/wallpapers/fade.lua" ]]; then
                fade_opt="--script=$HOME/.config/wallpapers/fade.lua --script-opts=fade_duration=1.0"
            fi
            
            mpvpaper "$monitor" "$wall" \
                -o "--no-audio --loop --fullscreen --panscan=1.0 --no-osc --no-osd-bar \
                    --geometry=100%x100% $fade_opt" &
        else
            # Static image settings
            mpvpaper "$monitor" "$wall" \
                -o "--loop-file=inf --fullscreen --panscan=1.0 --no-osc --no-osd-bar --geometry=100%x100%" &
        fi
    done
}

if [[ "$1" == "--init" ]]; then
    if [[ -f "$CURRENT_WALLPAPER_FILE" ]]; then
        wall=$(cat "$CURRENT_WALLPAPER_FILE")
        apply_wallpaper "$wall"
    else
        # Default fallback
        wall=$(find "$WALL_DIR" -type f | head -n 1)
        apply_wallpaper "$wall"
    fi
    exit 0
fi

# Show rofi menu
CACHE_DIR="$HOME/.cache/wallpaper-thumbnails"
mkdir -p "$CACHE_DIR"

vids=$(find "$WALL_DIR" -type f \( -iname '*.mp4' -o -iname '*.mkv' -o -iname '*.webm' \) 2>/dev/null)
imgs=$(find "$WALL_DIR" -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' \) 2>/dev/null)

all_walls=$(echo -e "$vids\n$imgs" | grep -v '^[[:space:]]*$')

# Generate input for rofi
rofi_input=""
while IFS= read -r wall; do
    [[ -z "$wall" ]] && continue
    name=$(basename "$wall")
    
    # Generate thumbnail
    thumb="$CACHE_DIR/${name}.jpg"
    if [[ ! -f "$thumb" ]]; then
        if [[ "$wall" =~ \.(mp4|webm|mkv)$ ]]; then
            ffmpegthumbnailer -i "$wall" -o "$thumb" -s 256 -q 8 -c jpeg >/dev/null 2>&1
        else
            magick "$wall[0]" -resize 256x256^ -gravity center -extent 256x256 "$thumb" >/dev/null 2>&1
        fi
    fi
    
    # Append to input list
    rofi_input+="${name}\0icon\x1f${thumb}\n"
done <<< "$all_walls"

# Show in rofi
selected_name=$(echo -en "$rofi_input" | rofi -dmenu -i -p "󰸉" -theme "$HOME/.config/rofi/themes/wallpaper-grid.rasi" -show-icons)

if [[ -n "$selected_name" ]]; then
    # Find full path mapping back to the name
    selected_path=$(echo "$all_walls" | grep -F "/$selected_name")
    if [[ -n "$selected_path" ]]; then
        # Pick the first match in case of duplicates
        apply_wallpaper "$(echo "$selected_path" | head -n 1)"
    fi
fi
