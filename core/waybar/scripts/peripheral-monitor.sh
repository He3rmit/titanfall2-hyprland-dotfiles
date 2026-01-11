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
    MODEL=$(echo "$INFO" | grep "model:" | cut -d: -f2 | xargs)
    PERCENT=$(echo "$INFO" | grep "percentage:" | awk '{print $2}' | tr -d '%')
    STATE=$(echo "$INFO" | grep "state:" | awk '{print $2}' | xargs)
    
    if [ -z "$PERCENT" ]; then continue; fi

    # Fix for the {} issue: Default empty state to 'active'
    if [ -z "$STATE" ]; then STATE="active"; fi

    TOOLTIP_MSG+="${MODEL}: ${PERCENT}% (${STATE})\n"

    if [[ "$STATE" == "charging" ]]; then IS_CHARGING=true; fi
    if [[ "$PERCENT" -le 20 ]]; then HAS_CRITICAL=true; fi

    # --- 2. CATEGORIZE (AGNOSTIC) ---
    if [[ "$DEV_PATH" == *"BAT"* ]]; then
        ICON="SYS"
        [[ "$STATE" == "charging" ]] && ICON="⚡"
        LAPTOP_BAT="${ICON}: ${PERCENT}%"
    else
        ICON=""
        [[ "$STATE" == "charging" ]] && ICON="⚡ "
        PERIPH_BAT="${ICON} ${PERCENT}%"
    fi
done < <(upower -e)

# --- 3. DETERMINE CLASS ---
[[ "$IS_CHARGING" == true ]] && MAIN_CLASS="charging"
[[ "$HAS_CRITICAL" == true ]] && MAIN_CLASS="critical"

# --- 4. FORMAT OUTPUT ---
if [ -n "$PERIPH_BAT" ]; then
    FINAL_TEXT="$PERIPH_BAT   $LAPTOP_BAT"
else
    FINAL_TEXT="$LAPTOP_BAT"
fi

# Clean tooltip for Waybar JSON
CLEAN_TOOLTIP=$(echo -e "$TOOLTIP_MSG" | sed ':a;N;$!ba;s/\n/\\n/g')

printf '{"text": "%s", "tooltip": "%s", "class": "%s"}\n' "$FINAL_TEXT" "$CLEAN_TOOLTIP" "$MAIN_CLASS"