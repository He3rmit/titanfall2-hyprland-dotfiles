#!/bin/bash
# -----------------------------------------------------
# Titanfall Clipboard Manager (Pilot Edition)
# -----------------------------------------------------

THEME="$HOME/.config/rofi/themes/clipboard.rasi"
CACHE_DIR="/tmp/cliphist-thumbnails"
mkdir -p "$CACHE_DIR"

# Keybind cheat sheet shown at the bottom of the popup
KEYBIND_HINTS="Enter: Paste  |  Alt+Del: Delete  |  Alt+Shift+Del: Wipe All  |  Alt+T: Type  |  Alt+O: Open URL  |  Alt+E: Edit"

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
            # Get image dimensions for a better label
            dims=$(cliphist decode "$id" | magick identify -format '%wx%h' - 2>/dev/null)
            if [[ -n "$dims" ]]; then
                label="[Image ${dims}]"
            else
                label="[Image]"
            fi
            echo -en "${id}\t${label}\0icon\x1f${preview_file}\n"
        else
            # Collapse whitespace for cleaner display
            clean=$(echo "$content" | tr '\n' ' ' | sed 's/  */ /g' | head -c 120)
            echo -en "${id}\t${clean}\0icon\x1ftext-x-generic\n"
        fi
    done
}

# Kill Rofi if already running
if pgrep -x "rofi" > /dev/null; then
    pkill rofi
    exit 0
fi

selection=$(generate_list | rofi -dmenu \
    -theme "$THEME" \
    -p "󰅇" \
    -mesg "$KEYBIND_HINTS" \
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
    0)  # ENTER — Paste
        cliphist decode "$clip_id" | wl-copy
        notify_pilot "Buffer Updated" "Data sequence ready."
        ;;
    10) # Alt+Delete — Delete Entry
        cliphist delete <<< "$selection"
        notify_pilot "Entry Purged" "Item removed from history."
        ;;
    11) # Alt+Shift+Delete — Wipe All
        cliphist wipe
        rm -rf "$CACHE_DIR"/*
        notify-send -u critical -a "Titanfall Systems" "DATABASE PURGED" "All clipboard records erased."
        ;;
    12) # Alt+T — Auto-Type
        cliphist decode "$clip_id" | wtype -
        ;;
    13) # Alt+O — Open URL
        url=$(cliphist decode "$clip_id")
        notify_pilot "Opening Uplink" "$url"
        xdg-open "$url"
        ;;
    14) # Alt+E — Edit in Terminal
        tmp_file="/tmp/cliphist-edit-$clip_id.txt"
        cliphist decode "$clip_id" > "$tmp_file"
        kitty --class floating -e nano "$tmp_file"
        [ -f "$tmp_file" ] && cat "$tmp_file" | wl-copy && rm "$tmp_file"
        ;;
esac