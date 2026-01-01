#!/bin/bash
# -----------------------------------------------------
# Titanfall Clipboard Manager (Pilot Edition)
# -----------------------------------------------------

THEME="$HOME/.config/rofi/themes/titanfall2.rasi"
CACHE_DIR="/tmp/cliphist-thumbnails"
mkdir -p "$CACHE_DIR"

# TITANFALL HUD COLORS
COLOR_BLUE="#4261ff"   # Pilot/Friendly Blue
COLOR_ORANGE="#ff8242" # Enemy/IMC Orange

notify_pilot() {
    notify-send -u normal -a "Titanfall Systems" -i "terminal" "$1" "$2"
}

generate_list() {
    cliphist list | while read -r line; do
        id=$(echo "$line" | cut -d$'\t' -f1)
        content=$(echo "$line" | cut -d$'\t' -f2-)
        if [[ "$content" =~ binary.*data ]]; then
            preview_file="$CACHE_DIR/${id}.png"
            if [ ! -f "$preview_file" ]; then
                cliphist decode "$id" | magick - -resize 64x64! "$preview_file" 2>/dev/null
            fi
            echo -en "${id}\t[ Captured Image ]\0icon\x1f${preview_file}\n"
        else
            echo -en "${id}\t${content}\0icon\x1ftext-x-generic\n"
        fi
    done
}

selection=$(generate_list | rofi -dmenu \
    -theme "$THEME" \
    -p "Data Core" \
    -display-columns 2 \
    -show-icons \
    -kb-custom-1 "Alt+Delete" \
    -kb-custom-2 "Alt+Shift+Delete" \
    -kb-custom-3 "Alt+t" \
    -kb-custom-4 "Alt+o" \
    -kb-custom-5 "Alt+e")

exit_code=$?
[ -z "$selection" ] && exit 0
clip_id=$(echo "$selection" | awk '{print $1}')

case $exit_code in
    0)  # ENTER
        cliphist decode "$clip_id" | wl-copy
        notify_pilot "Buffer Updated" "Pilot, data sequence ready."
        ;;
    10) # Alt+Delete
        cliphist delete <<< "$selection"
        notify_pilot "Entry Purged" "Security protocol active. Item deleted."
        ;;
    11) # Alt+Shift+Delete
        cliphist wipe
        rm -rf "$CACHE_DIR"/*
        notify-send -u critical -a "Titanfall Systems" "DATABASE PURGED" "All records have been erased."
        ;;
    12) # Alt+T
        notify_pilot "Auto-Type Engaged" "Injecting keystrokes into local terminal..."
        cliphist decode "$clip_id" | wtype -
        ;;
    13) # Alt+O
        url=$(cliphist decode "$clip_id")
        notify_pilot "Protocol 2" "Opening external uplink: $url"
        xdg-open "$url"
        ;;
    14) # Alt+E
        tmp_file="/tmp/cliphist-edit-$clip_id.txt"
        cliphist decode "$clip_id" > "$tmp_file"
        notify_pilot "Editing Record" "Opening secure editor..."
        kitty --class floating -e nano "$tmp_file"
        [ -f "$tmp_file" ] && cat "$tmp_file" | wl-copy && rm "$tmp_file"
        ;;
esac