2#!/usr/bin/env bash

# --- Config ---
LAPTOP="eDP-1"          # your laptop output
WATCH_INTERVAL=2         # seconds between checking outputs

# Function to get connected outputs
get_connected_outputs() {
    hyprctl devices | grep "Output " | grep "Connected" | awk '{print $2}'
}

# Function to get resolution of an output
get_resolution() {
    local OUTPUT=$1
    hyprctl devices | grep -A1 "$OUTPUT" | grep "Mode" | awk '{print $2 "x" $3}' | head -n1
}

# Function to mirror external monitors
mirror_external() {
    local LAP_RES=$(get_resolution "$LAPTOP")
    local CONNECTED=$(get_connected_outputs)

    for OUT in $CONNECTED; do
        if [ "$OUT" != "$LAPTOP" ]; then
            echo "Mirroring $OUT to $LAPTOP..."
            # Set external monitor to laptop's resolution and position
            hyprctl dispatch output "$OUT,mode=$LAP_RES,pos=0,0,scale=1,transform=normal"
        fi
    done
    # Reload Hyprland to apply changes
    hyprctl reload
}

# --- Main loop ---
while true; do
    mirror_external
    sleep $WATCH_INTERVAL
done
