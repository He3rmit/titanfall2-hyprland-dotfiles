#!/bin/bash
# ==============================================================================
# MODULE: 00-dependencies.sh
# Purpose: Installs core system dependencies early on. This checklist ensures
#          a "Pure Hyprland" install has everything it needs (like polkit)
#          even if run on a base Arch Linux install without KDE Plasma.
# ==============================================================================

source "$INSTALLER_DIR/scripts/utils.sh"

print_step "Validating Core Dependencies for Pure Hyprland..."

# Core packages needed regardless of base environment
CORE_PACKAGES=(
    # --- CORE INSTALLER DEPS ---
    "stow"
    
    # --- HYPRLAND SYSTEM DEPS ---
    "hyprland"
    "xdg-desktop-portal"
    "xdg-desktop-portal-hyprland"
    "qt5-wayland"
    "qt6-wayland"
    "nwg-look"
    
    # --- GUI COMPONENTS ---
    "waybar"
    "swaync"
    "rofi-wayland"
    "kitty"
    "dolphin"
    
    # --- HYPRLAND DAEMONS & SYSTEM UTILS ---
    "hypridle"
    "hyprlock"
    "hyprpicker"
    "hyprsunset"
    "wlogout"
    "wl-clipboard"
    "cliphist"
    "libnotify"
    "xorg-xhost"
    "xdg-user-dirs"
    
    # --- SCREENSHOT & WALLPAPER ---
    "grim"
    "slurp"
    "swappy"
    "mpvpaper"
    "jq"
    
    # --- HARDWARE CONTROL ---
    "upower"
    "brightnessctl"
    "power-profiles-daemon"
    "playerctl"
    "networkmanager"
    
    # --- CORE UTILITIES ---
    "unzip"
    "wget"
    
    # --- AUDIO & BLUETOOTH ---
    "wireplumber"
    "pipewire"
    "pipewire-pulse"
    "pavucontrol"
    "easyeffects"
    "blueman"
    
    # --- THEME & FONTS ---
    "ttf-sharetech-mono-nerd"
    "ttf-jetbrains-mono-nerd"
    "ttf-nerd-fonts-symbols"
    "noto-fonts-emoji"
    "obsidian-icon-theme"
    "starship"
    "fastfetch"
    "wtfutil-bin"
)

# Fallback packages only needed if we are NOT running alongside KDE Plasma
STANDALONE_PACKAGES=(
    "polkit-kde-agent" # Required for sudo prompts in GUI apps
    "gnome-keyring"    # Required for managing secrets/passwords
    "sddm"             # Display Manager
)

# Function to check and install
install_pkg() {
    local pkg=$1
    if ! pacman -Qi "$pkg" &> /dev/null && ! pacman -Qq "$pkg" &> /dev/null; then
        echo "Installing $pkg..."
        paru -S --noconfirm "$pkg"
    else
        echo "✅ $pkg is already installed."
    fi
}

print_step "Installing Core Packages..."
for pkg in "${CORE_PACKAGES[@]}"; do
    install_pkg "$pkg"
done

# Smart Detection: Are we running alongside Plasma?
if pacman -Qi "plasma-desktop" &> /dev/null; then
    print_success "KDE Plasma detected. Skipping redundant daemons (Polkit, Keyring)."
else
    print_warning "Naked Arch install detected. Installing standalone daemons..."
    for pkg in "${STANDALONE_PACKAGES[@]}"; do
        install_pkg "$pkg"
    done
fi

print_success "Dependencies nominal. System is ready for deployment."
