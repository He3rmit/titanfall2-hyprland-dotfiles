#!/bin/bash

# --- VARIABLES ---
LAPTOP_BAT=""
PERIPH_BAT=""
TOOLTIP_MSG=""
MAIN_CLASS="discharging"
HAS_CRITICAL=false
IS_CHARGING=false

# --- 1. SCAN LOOP ---
# We loop through EVERY power device upower sees
while read -r DEV_PATH; do
    # Skip Line Power (AC) and generic DisplayDevice
    if [[ "$DEV_PATH" == *"line_power"* ]] || [[ "$DEV_PATH" == *"DisplayDevice"* ]]; then
        continue
    fi

    # Get Data
    INFO=$(upower -i "$DEV_PATH")
    MODEL=$(echo "$INFO" | grep "model:" | cut -d: -f2 | xargs)
    PERCENT=$(echo "$INFO" | grep "percentage:" | awk '{print $2}' | tr -d '%')
    STATE=$(echo "$INFO" | grep "state:" | awk '{print $2}' | xargs)
    
    # Skip if no data
    if [ -z "$PERCENT" ]; then continue; fi

    # Add to Tooltip List (e.g. "ASUS Battery: 79% (discharging)")
    TOOLTIP_MSG+="${MODEL}: ${PERCENT}% (${STATE})\n"

    # Check Status for Coloring
    if [[ "$STATE" == "charging" ]]; then IS_CHARGING=true; fi
    if [[ "$PERCENT" -le 20 ]]; then HAS_CRITICAL=true; fi

    # --- 2. CATEGORIZE DEVICES ---
    
    # Automatically find the internal system battery
    if [[ "$DEV_PATH" == *"BAT"* ]]; then
        ICON="SYS"
        if [[ "$STATE" == "charging" ]]; then ICON="⚡"; fi
        LAPTOP_BAT="${ICON}: ${PERCENT}%"
    
    # IS IT A PERIPHERAL? (Everything else)
    else
        ICON="" # Generic Bluetooth Icon
        if [[ "$STATE" == "charging" ]]; then ICON="⚡ "; fi
        PERIPH_BAT="${ICON} ${PERCENT}%"
    fi

done < <(upower -e)

# --- 3. DETERMINE FINAL CLASS ---
if [ "$IS_CHARGING" = true ]; then
    MAIN_CLASS="charging"
elif [ "$HAS_CRITICAL" = true ]; then
    MAIN_CLASS="critical"
fi

# --- 4. FORMAT OUTPUT ---
# If we have a mouse, show " 23%  SYS: 79%"
# If no mouse, show "SYS: 79%"
if [ -n "$PERIPH_BAT" ]; then
    FINAL_TEXT="$PERIPH_BAT   $LAPTOP_BAT"
else
    FINAL_TEXT="$LAPTOP_BAT"
fi

# Output JSON
echo "{\"text\": \"$FINAL_TEXT\", \"tooltip\": \"$TOOLTIP_MSG\", \"class\": \"$MAIN_CLASS\"}"