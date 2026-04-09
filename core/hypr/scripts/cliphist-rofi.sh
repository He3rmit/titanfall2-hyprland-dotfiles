#!/bin/bash
# -----------------------------------------------------
# Titanfall Clipboard Manager (Pilot Edition)
# -----------------------------------------------------

THEME="$HOME/.config/rofi/themes/clipboard.rasi"
CACHE_DIR="/tmp/cliphist-thumbnails"
mkdir -p "$CACHE_DIR"

# Keybind cheat sheet shown at the bottom of the popup
KEYBIND_HINTS="Enter: Paste  |  Alt+P: Preview  |  Alt+Del: Delete  |  Alt+Shift+Del: Wipe  |  Alt+T: Type  |  Alt+O: URL  |  Alt+E: Edit"

notify_pilot() {
    notify-send -u normal -a "Titanfall Systems" -i "terminal" "$1" "$2"
}

generate_list() {
    cliphist list | while IFS= read -r line; do
        # Extract ID and Content instantaneously using bash native substring splitting
        id="${line%%$'\t'*}"
        content="${line#*$'\t'}"
        
        if [[ "$content" =~ binary.*data ]]; then
            preview_file="$CACHE_DIR/${id}.png"
            if [ ! -f "$preview_file" ]; then
                # Run heavily blocking thumbnail generation in background, output redirected so bash substitute doesn't wait
                # Generates a premium 64x64 center-cropped square instead of squished aspect ratios
                (cliphist decode "$id" | magick - -resize '64x64^' -gravity center -extent 64x64 "$preview_file" >/dev/null 2>&1) &
            fi
            
            # Extract dimensions directly from cliphist output (e.g., "[[ binary data 198 KiB png 412x1010 ]]")
            if [[ "$content" =~ ([0-9]+x[0-9]+) ]]; then
                label="[Image ${BASH_REMATCH[1]}]"
            else
                label="[Image]"
            fi
            
            echo -en "${id}\t${label}\0icon\x1f${preview_file}\n"
        else
            # Clean string purely in bash (no slow sub-processes)
            # Remove any extra spacing
            clean="${content//  / }"
            clean="${clean//  / }"
            echo -en "${id}\t${clean:0:120}\0icon\x1ftext-x-generic\n"
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
    -multi-select \
    -kb-custom-1 "Alt+Delete" \
    -kb-custom-2 "Alt+Shift+Delete" \
    -kb-custom-3 "Alt+t" \
    -kb-custom-4 "Alt+o" \
    -kb-custom-5 "Alt+e" \
    -kb-custom-6 "Alt+p")

exit_code=$?
[ -z "$selection" ] && exit 0
clip_ids=$(echo "$selection" | awk '{print $1}')

case $exit_code in
    0)  # ENTER — Paste (First item only)
        first_id=$(echo "$clip_ids" | head -n 1)
        cliphist decode "$first_id" | wl-copy
        notify_pilot "Buffer Updated" "Data sequence ready."
        ;;
    15) # Alt+P — Preview Image (First item only)
        first_id=$(echo "$clip_ids" | head -n 1)
        tmp_img="$CACHE_DIR/preview_$first_id.png"
        cliphist decode "$first_id" > "$tmp_img"
        xdg-open "$tmp_img" &
        notify_pilot "Visual Feed Active" "Opening image preview..."
        ;;
    10) # Alt+Delete — Delete Entry (Native bulk)
        cliphist delete <<< "$selection"
        notify_pilot "Entry Purged" "Item(s) removed from history."
        ;;
    11) # Alt+Shift+Delete — Wipe All
        cliphist wipe
        rm -rf "$CACHE_DIR"/*
        notify-send -u critical -a "Titanfall Systems" "DATABASE PURGED" "All clipboard records erased."
        ;;
    12) # Alt+T — Auto-Type
        echo "$clip_ids" | while read -r id; do
            cliphist decode "$id" | wtype -
            sleep 0.1 # small pause between consecutive bulk pastes
        done
        ;;
    13) # Alt+O — Open URL
        echo "$clip_ids" | while read -r id; do
            url=$(cliphist decode "$id")
            notify_pilot "Opening Uplink" "$url"
            xdg-open "$url" &
        done
        ;;
    14) # Alt+E — Edit in Terminal
        tmp_file="/tmp/cliphist-edit-$$.txt"
        > "$tmp_file"
        echo "$clip_ids" | while read -r id; do
            cliphist decode "$id" >> "$tmp_file"
            echo "" >> "$tmp_file" # separator
        done
        notify_pilot "Editing Multi-Record" "Opening secure editor..."
        kitty --class floating -e nano "$tmp_file"
        if [ -s "$tmp_file" ]; then
            cat "$tmp_file" | wl-copy
            rm "$tmp_file"
            notify_pilot "Buffer Updated" "Combined custom string saved to clipboard."
        fi
        ;;
esac