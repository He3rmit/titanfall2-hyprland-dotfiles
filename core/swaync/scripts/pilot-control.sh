#!/bin/bash

case "$1" in
    wifi)
        # Toggle Wifi
        nmcli radio wifi | grep -q "enabled" && nmcli radio wifi off || nmcli radio wifi on
        ;;
    bluetooth)
        # Toggle Bluetooth
        rfkill list bluetooth | grep -q "Soft blocked: yes" && rfkill unblock bluetooth || rfkill block bluetooth
        ;;
    perf)
        # Set Performance
        powerprofilesctl set performance
        notify-send -u low "PILOT HUD" "Protocol: PERFORMANCE"
        ;;
    bal)
        # Set Balanced
        powerprofilesctl set balanced
        notify-send -u low "PILOT HUD" "Protocol: BALANCED"
        ;;
    save)
        # Set Power Saver
        powerprofilesctl set power-saver
        notify-send -u low "PILOT HUD" "Protocol: CONSERVATION"
        ;;
esac