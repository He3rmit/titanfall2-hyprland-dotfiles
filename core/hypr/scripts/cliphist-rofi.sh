#!/bin/bash
# -----------------------------------------------------
# Titanfall Clipboard Manager (Robust Image Detection)
# -----------------------------------------------------

THEME="$HOME/.config/rofi/themes/titanfall2.rasi"
CACHE_DIR="/tmp/cliphist-thumbnails"
mkdir -p "$CACHE_DIR"

cliphist list | while read -r line; do
    # Extract ID (first field before tab)
    id=$(echo "$line" | cut -d$'\t' -f1)
    
    # Extract Content (everything after first tab)
    content=$(echo "$line" | cut -d$'\t' -f2-)
    
    # CHECK: Does the content look like an image marker?
    # Matches: "[binary", "[[ binary", "binary data", etc.
    if [[ "$content" =~ binary.*data ]]; then
        preview_file="$CACHE_DIR/${id}.png"
        
        # Generate thumbnail if missing
        if [ ! -f "$preview_file" ]; then
            cliphist decode "$id" | magick - -resize 64x64! "$preview_file" 2>/dev/null
        fi
        
        # Send to Rofi: ID+Content + Icon Path
        if [ -f "$preview_file" ]; then
            echo -en "${id}\t${content}\0icon\x1f${preview_file}\n"
        else
            echo -en "${id}\t${content}\0icon\x1fimage-x-generic\n"
        fi
    else
        # It is text -> Use generic text icon
        echo -en "${id}\t${content}\0icon\x1ftext-x-generic\n"
    fi
    
done | rofi -dmenu \
    -theme "$THEME" \
    -p "Clipboard" \
    -display-columns 2 \
    -show-icons \
    -kb-custom-1 "Alt+Delete" \
    | \
    while read -r selection; do
        exit_code=$?
        
        # Extract ID to handle the action
        clip_id=$(echo "$selection" | awk '{print $1}')

        if [ $exit_code -eq 10 ]; then
            cliphist delete <<< "$selection"
            exec "$0"
        elif [ -n "$selection" ]; then
            cliphist decode "$clip_id" | wl-copy
            exit 0
        fi
    done