#!/bin/bash
# Fixed Titanfall Clipboard Menu
cliphist list | rofi -dmenu -i -p "Clipboard:" -theme ~/.config/rofi/themes/titanfall2.rasi | cliphist decode | wl-copy