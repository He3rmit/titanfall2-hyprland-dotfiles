#!/bin/bash
# Webcam Toggle Script for Hyprland (ASUS Vivobook compatible)
# Requires: v4l-utils, libnotify (for notify-send), and optionally sudo access for modprobe fallback.

DEVICE="/dev/video0"

# Check if device exists
if [ ! -e "$DEVICE" ]; then
    notify-send "📷 No webcam device found"
    exit 1
fi

# Try to detect if the webcam supports 'privacy' control (ASUS models often do)
if v4l2-ctl -d "$DEVICE" --all 2>/dev/null | grep -q "privacy"; then
    STATUS=$(v4l2-ctl -d "$DEVICE" --get-ctrl=privacy 2>/dev/null | awk '{print $2}')
    if [ "$STATUS" -eq 0 ]; then
        v4l2-ctl -d "$DEVICE" --set-ctrl=privacy=1
        notify-send "📷 Webcam Disabled"
    else
        v4l2-ctl -d "$DEVICE" --set-ctrl=privacy=0
        notify-send "📷 Webcam Enabled"
    fi
else
    # Fallback: toggle kernel module if privacy control not available
    if lsmod | grep -q uvcvideo; then
        sudo modprobe -r uvcvideo && notify-send "📷 Webcam Disabled"
    else
        sudo modprobe uvcvideo && notify-send "📷 Webcam Enabled"
    fi
fi

