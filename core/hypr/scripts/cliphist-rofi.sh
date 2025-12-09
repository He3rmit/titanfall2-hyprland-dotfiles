#!/bin/bash
# -----------------------------------------------------
# Titanfall Clipboard Manager (Multi-Tool Edition)
# -----------------------------------------------------
# Keybinds:
# ENTER  : Paste (Standard)
# Alt + T: Type (Simulate Keystrokes)
# Alt + O: Open (Treat as URL)
# Alt + E: Edit (Open in Editor)
# Alt + D: Delete Item
# Alt + W: Wipe History
# -----------------------------------------------------

THEME="$HOME/.config/rofi/themes/titanfall2.rasi"
CACHE_DIR="/tmp/cliphist-thumbnails"

# Ensure cache dir exists
mkdir -p "$CACHE_DIR"

# 1. READ HISTORY & GENERATE THUMBNAILS
cliphist list | while read -r line; do
    id=$(echo "$line" | cut -d$'\t' -f1)
    content=$(echo "$line" | cut -d$'\t' -f2-)
    
    # Check for Image (Regex match for "binary" followed by "data")
    if [[ "$content" =~ binary.*data ]]; then
        preview_file="$CACHE_DIR/${id}.png"
        
        # Create thumbnail if missing (Resize to 64px height)
        if [ ! -f "$preview_file" ]; then
            cliphist decode "$id" | magick - -resize 64x64! "$preview_file" 2>/dev/null
        fi
        
        if [ -f "$preview_file" ]; then
            echo -en "${id}\t[ Captured Image ]\0icon\x1f${preview_file}\n"
        else
            echo -en "${id}\t[ Image (No Preview) ]\0icon\x1fimage-x-generic\n"
        fi
    else
        # Regular text
        echo -en "${id}\t${content}\0icon\x1ftext-x-generic\n"
    fi
done | rofi -dmenu \
    -theme "$THEME" \
    -p "Data Core" \
    -display-columns 2 \
    -show-icons \
    -kb-custom-1 "Alt+Delete" \
    -kb-custom-2 "Alt+Shift+Delete" \
    -kb-custom-3 "Alt+t" \
    -kb-custom-4 "Alt+o" \
    -kb-custom-5 "Alt+e" \
    | \
    while read -r selection; do
        exit_code=$?
        clip_id=$(echo "$selection" | awk '{print $1}')

        case $exit_code in
            0)  # ENTER - Standard Paste
                cliphist decode "$clip_id" | wl-copy
                ;;

            10) # Alt+Delete - Delete Item
                cliphist delete <<< "$selection"
                exec "$0" # Reload
                ;;

            11) # Alt+Shift+Delete - Wipe History
                cliphist wipe
                rm -rf "$CACHE_DIR"/*
                notify-send -u critical "Titanfall Systems" "Database Purged."
                exit 0
                ;;

            12) # Alt+T - Auto-Type (Hackerman Mode)
                # Decodes text and uses wtype to simulate keystrokes
                text=$(cliphist decode "$clip_id")
                wtype "$text"
                ;;

            13) # Alt+O - Open as URL
                # Decodes text and tries to open with xdg-open
                url=$(cliphist decode "$clip_id")
                xdg-open "$url"
                ;;

            14) # Alt+E - Edit in Terminal
                # Decodes to tmp file -> Opens in nano/vim -> Copies back
                tmp_file="/tmp/cliphist-edit-$clip_id.txt"
                cliphist decode "$clip_id" > "$tmp_file"
                
                # Open in your preferred terminal (kitty) + editor (nano/vim)
                kitty --class floating -e nano "$tmp_file"
                
                # After editor closes, copy back to clipboard
                cat "$tmp_file" | wl-copy
                rm "$tmp_file"
                notify-send "Titanfall Systems" "Edited entry copied to buffer."
                ;;
        esac
    done