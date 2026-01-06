#!/bin/bash

# initialize variables
TOOLTIP=""
MAIN_TEXT=""
MAIN_CLASS=""
MAIN_PERCENT=0
PERIPHERAL_FOUND=false

# Loop through ALL power devices
while read -r DEV_PATH; do
    # Skip line power (AC) and generic DisplayDevice
    if [[ "$DEV_PATH" == *"line_power"* ]] || [[ "$DEV_PATH" == *"DisplayDevice"* ]]; then
        continue
    fi

    INFO=$(upower -i "$DEV_PATH")
    
    # Extract details
    MODEL=$(echo "$INFO" | grep "model:" | awk -F: '{print $2}' | xargs)
    PERCENT=$(echo "$INFO" | grep "percentage:" | awk '{print $2}' | tr -d '%')
    STATE=$(echo "$INFO" | grep "state:" | awk '{print $2}' | xargs)
    
    # Skip if no percentage data (some dummy devices)
    if [ -z "$PERCENT" ]; then continue; fi

    # Build the Tooltip (Add every device found)
    # Format: "Model: 79% (charging)\n"
    TOOLTIP+="${MODEL}: ${PERCENT}% (${STATE})\r"

    # DETERMINE MAIN DISPLAY
    # If this is NOT a system battery and we haven't found a peripheral yet...
    if [[ "$DEV_PATH" != *"BAT"* ]] && [[ "$MODEL" != *"ASUS Battery"* ]] && [ "$PERIPHERAL_FOUND" = false ]; then
        PERIPHERAL_FOUND=true
        MAIN_PERCENT=$PERCENT
        
        # Icon Logic
        ICON=""
        MAIN_CLASS="discharging"
        
        if [[ "$STATE" == "charging" ]]; then
            ICON="⚡ "
            MAIN_CLASS="charging"
        elif [[ "$PERCENT" -le 20 ]]; then
            MAIN_CLASS="critical"
        fi
        
        MAIN_TEXT="$ICON $PERCENT%"
    fi

done < <(upower -e)

# OUTPUT LOGIC
if [ "$PERIPHERAL_FOUND" = true ]; then
    # We found a mouse/keyboard! Show it on the bar, but show ALL batteries in tooltip.
    echo "{\"text\": \"$MAIN_TEXT\", \"tooltip\": \"$TOOLTIP\", \"class\": \"$MAIN_CLASS\", \"percentage\": $MAIN_PERCENT}"
else
    # No peripheral found. Hide the module to keep the bar clean.
    # (The Laptop Battery module is already handling the system power display)
    echo "{}"
fi