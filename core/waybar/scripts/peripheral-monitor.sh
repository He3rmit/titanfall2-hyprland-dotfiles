#!/bin/bash

# --- VARIABLES ---
LAPTOP_BAT=""
PERIPH_BAT=""
TOOLTIP_MSG=""
MAIN_CLASS="discharging"
HAS_CRITICAL=false
IS_CHARGING=false

# --- 1. DIRECT KERNEL READ FOR LAPTOP BATTERY (THE FIX) ---
# This bypasses upower entirely and reads straight from the hardware
SYS_BAT=$(ls -d /sys/class/power_supply/BAT* | head -n 1 2>/dev/null)

if [ -n "$SYS_BAT" ]; then
    BAT_LEVEL=$(cat "$SYS_BAT/capacity")
    # Kernel statuses are capitalized (Charging, Discharging, Full), so we make them lowercase
    BAT_STATE=$(cat "$SYS_BAT/status" | tr '[:upper:]' '[:lower:]') 
    
    ICON="SYS"
    [[ "$BAT_STATE" == "charging" ]] && ICON="⚡"
    LAPTOP_BAT="${ICON}: ${BAT_LEVEL}%"
    
    if [[ "$BAT_STATE" == "charging" ]]; then IS_CHARGING=true; fi
    if [[ "$BAT_LEVEL" -le 20 ]]; then HAS_CRITICAL=true; fi
    
    TOOLTIP_MSG+="Laptop Battery: ${BAT_LEVEL}% (${BAT_STATE})\n"
fi

# --- 2. UPOWER LOOP FOR PERIPHERALS ONLY ---
while read -r DEV_PATH; do
    # Skip display devices, AC power, AND the laptop battery (since we handled it above)
    if [[ "$DEV_PATH" == *"line_power"* ]] || [[ "$DEV_PATH" == *"DisplayDevice"* ]] || [[ "$DEV_PATH" == *"BAT"* ]]; then
        continue
    fi

    INFO=$(upower -i "$DEV_PATH")
    MODEL=$(echo "$INFO" | grep "model:" | cut -d: -f2 | xargs | sed 's/&/\&amp;/g')
    PERCENT=$(echo "$INFO" | grep "percentage:" | awk '{print $2}' | tr -d '%')
    STATE=$(echo "$INFO" | grep "state:" | awk '{print $2}' | xargs)
    
    if [ -z "$PERCENT" ]; then continue; fi
    if [ -z "$STATE" ]; then STATE="active"; fi

    # Phantom 0% fix for peripherals
    if [[ "$PERCENT" == "0" ]]; then continue; fi

    TOOLTIP_MSG+="${MODEL}: ${PERCENT}% (${STATE})\n"

    # Smart Icon Logic
    if [[ "$DEV_PATH" == *"mouse"* ]]; then DEV_ICON="󰍽"
    elif [[ "$DEV_PATH" == *"keyboard"* ]]; then DEV_ICON="󰌌"
    elif [[ "$DEV_PATH" == *"headset"* ]] || [[ "$DEV_PATH" == *"audio"* ]]; then DEV_ICON="󰋋"
    else DEV_ICON=""; fi

    [[ "$STATE" == "charging" ]] && DEV_ICON="⚡$DEV_ICON"
    
    PERIPH_BAT+="$DEV_ICON ${PERCENT}%  "
done < <(upower -e)

# --- 3. DETERMINE CLASS ---
[[ "$IS_CHARGING" == true ]] && MAIN_CLASS="charging"
[[ "$HAS_CRITICAL" == true ]] && MAIN_CLASS="critical"

# --- 4. FORMAT OUTPUT (AGNOSTIC FIX) ---
PERIPH_BAT=$(echo "$PERIPH_BAT" | xargs)

if [ -n "$PERIPH_BAT" ] && [ -n "$LAPTOP_BAT" ]; then
    # Both exist: Put a separator between them
    FINAL_TEXT="$PERIPH_BAT | $LAPTOP_BAT"
elif [ -n "$PERIPH_BAT" ]; then
    # Only peripherals exist (Desktop PC scenario)
    FINAL_TEXT="$PERIPH_BAT"
elif [ -n "$LAPTOP_BAT" ]; then
    # Only laptop battery exists (No wireless devices connected)
    FINAL_TEXT="$LAPTOP_BAT"
else
    # Neither exist (Desktop PC with wired mouse/keyboard)
    FINAL_TEXT=""
fi

CLEAN_TOOLTIP=$(echo -e "$TOOLTIP_MSG" | sed ':a;N;$!ba;s/\n/\\n/g')
printf '{"text": "%s", "tooltip": "%s", "class": "%s"}\n' "$FINAL_TEXT" "$CLEAN_TOOLTIP" "$MAIN_CLASS"

# --- 5. SAFETY CHECKS (Prevent Spam) ---
# Now uses the highly reliable kernel data instead of upower
if [ -n "$SYS_BAT" ]; then
    if [[ "$BAT_LEVEL" -le 20 ]] && [[ "$BAT_STATE" != "charging" ]]; then
        if [ ! -f /tmp/reactor_instability_sent ]; then
            notify-send -u critical "REACTOR INSTABILITY" "Battery Level: ${BAT_LEVEL}% - Seek Power Source"
            touch /tmp/reactor_instability_sent
        fi
    else
        rm -f /tmp/reactor_instability_sent
    fi
fi