#!/usr/bin/env bash
# ==============================================================================
# WAYBAR HUD SWITCHER
# ==============================================================================

WAYBAR_DIR="$HOME/.config/waybar"
CONFIG_FILE="$WAYBAR_DIR/config.jsonc"
STYLE_FILE="$WAYBAR_DIR/style.css"

# Look inside the dotfiles source to avoid Stow symlink issues
LAYOUTS_DIR="$HOME/dotfiles/core/waybar/layouts"
STYLES_DIR="$HOME/dotfiles/core/waybar/styles"
ROFI_THEME="$HOME/.config/rofi/themes/runner.rasi"

# Ensure origin directories exist just in case
mkdir -p "$LAYOUTS_DIR" "$STYLES_DIR"

# 1. Ask what to change
MODE=$(echo -e "Change Layout (Modules)\nChange Style (CSS)\nChange Direction (Top/Bottom/Left/Right)" | rofi -dmenu -i -p "󰸉 Waybar" -theme "$ROFI_THEME")

if [[ -z "$MODE" ]]; then
    exit 0
fi

if [[ "$MODE" == "Change Layout (Modules)" ]]; then
    # 2a. List layouts
    cd "$LAYOUTS_DIR" || exit 1
    options=$(ls -1 *.jsonc 2>/dev/null | sed 's/\.jsonc$//')
    
    if [[ -z "$options" ]]; then
        notify-send "Waybar Switcher" "No layouts found!"
        exit 1
    fi
    
    selected_name=$(echo -e "$options" | rofi -dmenu -i -p "󰸉 Layout" -theme "$ROFI_THEME")
    
    if [[ -n "$selected_name" ]]; then
        target_file="$LAYOUTS_DIR/${selected_name}.jsonc"
        
        # If preserving the same Axis, sync the position memory!
        if [[ -f "$CONFIG_FILE" ]]; then
            CURRENT_POS=$(grep -Eo '"position": *"[a-zA-Z]+"' "$CONFIG_FILE" | cut -d'"' -f4 | head -n 1)
            CURRENT_NAME=$(readlink -f "$CONFIG_FILE")
            
            IS_CURRENT_SIDEBAR=0; IS_TARGET_SIDEBAR=0
            [[ "$CURRENT_NAME" == *"Sidebar"* ]] && IS_CURRENT_SIDEBAR=1
            [[ "$target_file" == *"Sidebar"* ]] && IS_TARGET_SIDEBAR=1
            
            IS_CURRENT_TOPBAR=0; IS_TARGET_TOPBAR=0
            [[ "$CURRENT_NAME" == *"Topbar"* || "$CURRENT_NAME" == *"Bottom"* ]] && IS_CURRENT_TOPBAR=1
            [[ "$target_file" == *"Topbar"* || "$target_file" == *"Bottom"* ]] && IS_TARGET_TOPBAR=1
            
            # Sync memory if axes match
            if [[ $IS_CURRENT_SIDEBAR -eq 1 && $IS_TARGET_SIDEBAR -eq 1 && -n "$CURRENT_POS" ]]; then
                sed -i -E 's/"position": *"[a-zA-Z]+"/"position": "'"$CURRENT_POS"'"/' "$target_file"
            fi
            if [[ $IS_CURRENT_TOPBAR -eq 1 && $IS_TARGET_TOPBAR -eq 1 && -n "$CURRENT_POS" ]]; then
                sed -i -E 's/"position": *"[a-zA-Z]+"/"position": "'"$CURRENT_POS"'"/' "$target_file"
            fi
        fi
        
        # Backup if it's not a symlink
        if [[ -f "$CONFIG_FILE" && ! -L "$CONFIG_FILE" ]]; then
            mv "$CONFIG_FILE" "${CONFIG_FILE}.bak"
        fi
        
        # Create new symlink
        ln -sf "$target_file" "$CONFIG_FILE"
        notify-send -t 2000 "Waybar Engine" "Layout updated: $selected_name"
        
        # Hot reload waybar
        pkill -SIGUSR2 waybar
    fi

elif [[ "$MODE" == "Change Style (CSS)" ]]; then
    # 2b. List styles
    cd "$STYLES_DIR" || exit 1
    options=$(ls -1 *.css 2>/dev/null | sed 's/\.css$//')
    
    if [[ -z "$options" ]]; then
        notify-send "Waybar Switcher" "No styles found!"
        exit 1
    fi
    
    selected_name=$(echo -e "$options" | rofi -dmenu -i -p "󰸉 Style" -theme "$ROFI_THEME")
    
    if [[ -n "$selected_name" ]]; then
        target_file="$STYLES_DIR/${selected_name}.css"
        
        # Backup if it's not a symlink
        if [[ -f "$STYLE_FILE" && ! -L "$STYLE_FILE" ]]; then
            mv "$STYLE_FILE" "${STYLE_FILE}.bak"
        fi
        
        # Create new symlink
        ln -sf "$target_file" "$STYLE_FILE"
        notify-send -t 2000 "Waybar Engine" "Style updated: $selected_name"
        
        # Hot reload waybar
        pkill -SIGUSR2 waybar
    fi
elif [[ "$MODE" == "Change Direction (Top/Bottom/Left/Right)" ]]; then
    # 2c. Ask for direction based on layout type
    REAL_CONFIG=$(readlink -f "$CONFIG_FILE")
    NAME=$(basename "$REAL_CONFIG")
    
    if [[ "$NAME" == *"Sidebar"* ]]; then
        DIRECTION=$(echo -e "left\nright" | rofi -dmenu -i -p "󰸉 Direction (Sidebar Mode)" -theme "$ROFI_THEME")
    elif [[ "$NAME" == *"Topbar"* ]] || [[ "$NAME" == *"Bottom"* ]]; then
        DIRECTION=$(echo -e "top\nbottom" | rofi -dmenu -i -p "󰸉 Direction (Topbar Mode)" -theme "$ROFI_THEME")
    else
        DIRECTION=$(echo -e "top\nbottom\nleft\nright" | rofi -dmenu -i -p "󰸉 Direction" -theme "$ROFI_THEME")
    fi
    
    if [[ -n "$DIRECTION" ]]; then
        if [[ -f "$REAL_CONFIG" ]]; then
            # Override whatever position the JSONC holds with the new one
            sed -i -E 's/"position": *"[a-zA-Z]+"/"position": "'"$DIRECTION"'"/' "$REAL_CONFIG"
            notify-send -t 2000 "Waybar Engine" "Direction updated: $DIRECTION"
            
            # Hot reload waybar
            pkill -SIGUSR2 waybar
        fi
    fi
fi

# ==============================================================================
# SWAYNC DYNAMIC ALIGNMENT
# ==============================================================================
sync_swaync_position() {
    local wbb_config="$HOME/.config/waybar/config.jsonc"
    local swaync_config="$HOME/.config/swaync/config.json"
    
    if [[ -f "$wbb_config" && -f "$swaync_config" ]]; then
        local wb_pos=$(grep -Eo '"position": *"[a-zA-Z]+"' "$wbb_config" | cut -d'"' -f4 | head -n 1)
        
        # Determine the module block containing the notification/tray icon
        local has_left=$(grep -E '"modules-left":.*("custom/notification"|"tray")' "$wbb_config")
        local has_center=$(grep -E '"modules-center":.*("custom/notification"|"tray")' "$wbb_config")
        local has_right=$(grep -E '"modules-right":.*("custom/notification"|"tray")' "$wbb_config")
        
        local target_x="right"
        local target_y="top"
        
        if [[ "$wb_pos" == "left" || "$wb_pos" == "right" ]]; then
            # Sidebar Mode (Vertical Flow)
            # Panel X-Axis locked to Waybar position
            target_x="$wb_pos"
            
            # Panel Y-Axis defined by internal structural modules (Left=Top, Center=Center, Right=Bottom)
            if [[ -n "$has_left" ]]; then target_y="top"
            elif [[ -n "$has_right" ]]; then target_y="bottom"
            elif [[ -n "$has_center" ]]; then target_y="center"
            fi
        else
            # Topbar/Bottombar Mode (Horizontal Flow)
            # Panel Y-Axis locked to Waybar position
            target_y="top"
            [[ "$wb_pos" == "bottom" ]] && target_y="bottom"
            
            # Panel X-Axis defined by internal structural modules (Left=Left, Center=Center, Right=Right)
            if [[ -n "$has_left" ]]; then target_x="left"
            elif [[ -n "$has_right" ]]; then target_x="right"
            elif [[ -n "$has_center" ]]; then target_x="center"
            fi
        fi
        
        sed -i -E 's/"positionX": *"[a-zA-Z]+"/"positionX": "'"$target_x"'"/' "$swaync_config"
        sed -i -E 's/"positionY": *"[a-zA-Z]+"/"positionY": "'"$target_y"'"/' "$swaync_config"
        
        swaync-client -R >/dev/null 2>&1
        swaync-client -rs >/dev/null 2>&1
    fi
}

sync_swaync_position
