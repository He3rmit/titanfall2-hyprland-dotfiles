#!/bin/bash

# --- VARIABLES ---
LAPTOP_BAT=""
PERIPH_BAT=""
TOOLTIP_MSG=""
MAIN_CLASS="discharging"
HAS_CRITICAL=false
IS_CHARGING=false

# --- 1. SCAN LOOP ---
while read -r DEV_PATH; do
    if [[ "$DEV_PATH" == *"line_power"* ]] || [[ "$DEV_PATH" == *"DisplayDevice"* ]]; then
        continue
    fi

    INFO=$(upower -i "$DEV_PATH")
    # Escape ampersands for Waybar GTK parsing
    MODEL=$(echo "$INFO" | grep "model:" | cut -d: -f2 | xargs | sed 's/&/\&amp;/g')
    PERCENT=$(echo "$INFO" | grep "percentage:" | awk '{print $2}' | tr -d '%')
    STATE=$(echo "$INFO" | grep "state:" | awk '{print $2}' | xargs)
    
    if [ -z "$PERCENT" ]; then continue; fi
    if [ -z "$STATE" ]; then STATE="active"; fi

    TOOLTIP_MSG+="${MODEL}: ${PERCENT}% (${STATE})\n"

    if [[ "$STATE" == "pending-charge" ]] || [[ "$STATE" == "charging" ]]; then IS_CHARGING=true; fi
    if [[ "$PERCENT" -le 20 ]]; then HAS_CRITICAL=true; fi

    # --- 2. CATEGORIZE (AGNOSTIC & MULTI-DEVICE) ---
    if [[ "$DEV_PATH" == *"BAT"* ]]; then
        ICON="SYS"
        [[ "$STATE" == "charging" ]] && ICON="⚡"
        LAPTOP_BAT="${ICON}: ${PERCENT}%"
    else
        # Smart Icon Logic: Detects device type but stays in one string
        if [[ "$DEV_PATH" == *"mouse"* ]]; then DEV_ICON="󰍽"
        elif [[ "$DEV_PATH" == *"keyboard"* ]]; then DEV_ICON="󰌌"
        elif [[ "$DEV_PATH" == *"headset"* ]] || [[ "$DEV_PATH" == *"audio"* ]]; then DEV_ICON="󰋋"
        else DEV_ICON=""; fi # Default icon for Bluetooth/Generic wireless

        [[ "$STATE" == "charging" ]] && DEV_ICON="⚡$DEV_ICON"
        
        # APPEND instead of replace so multiple devices show up
        PERIPH_BAT+="$DEV_ICON ${PERCENT}%  "
    fi
done < <(upower -e)

# --- 3. DETERMINE CLASS ---
[[ "$IS_CHARGING" == true ]] && MAIN_CLASS="charging"
[[ "$HAS_CRITICAL" == true ]] && MAIN_CLASS="critical"

# --- 4. FORMAT OUTPUT (THIS WAS MISSING) ---
# Trim trailing spaces from multi-device string
PERIPH_BAT=$(echo "$PERIPH_BAT" | xargs)

if [ -n "$PERIPH_BAT" ]; then
    FINAL_TEXT="$PERIPH_BAT | $LAPTOP_BAT"
else
    FINAL_TEXT="$LAPTOP_BAT"
fi

# Clean tooltip for JSON
CLEAN_TOOLTIP=$(echo -e "$TOOLTIP_MSG" | sed ':a;N;$!ba;s/\n/\\n/g')

# OUTPUT TO WAYBAR (Essential!)
printf '{"text": "%s", "tooltip": "%s", "class": "%s"}\n' "$FINAL_TEXT" "$CLEAN_TOOLTIP" "$MAIN_CLASS"

# --- 5. SAFETY CHECKS (Prevent Spam) ---
# Get the battery percentage and state again for the main battery
BAT_PATH=$(upower -e | grep 'battery' | head -n 1)

# Only proceed if a battery was actually found
if [ -n "$BAT_PATH" ]; then
    BAT_INFO=$(upower -i "$BAT_PATH")
    BAT_LEVEL=$(echo "$BAT_INFO" | grep percentage | awk '{print $2}' | tr -d '%')
    BAT_STATE=$(echo "$BAT_INFO" | grep state | awk '{print $2}')

    # Trigger the "Nuclear" Alert at 20%
    # LOGIC: If Low AND Discharging AND We haven't warned yet...
    if [[ "$BAT_LEVEL" -le 20 ]] && [[ "$BAT_STATE" != "charging" ]]; then
        if [ ! -f /tmp/reactor_instability_sent ]; then
            notify-send -u critical "REACTOR INSTABILITY" "Battery Level: $BAT_LEVEL% - Seek Power Source"
            # Create a 'lock file' so we don't spam again
            touch /tmp/reactor_instability_sent
        fi
    else
        # If we are charging or safe, reset the lock file so it can warn us next time
        rm -f /tmp/reactor_instability_sent
    fi
fi