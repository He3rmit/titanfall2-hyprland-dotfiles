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
    "xdg-desktop-portal-gtk"  # Essential for file pickers & settings
    "xwaylandvideobridge"     # Allows screen sharing for X11 apps like Discord
    "qt5-wayland"
    "qt6-wayland"
    "nwg-look"
    "nss-mdns"                # Required for local hostname resolution (.local)
    
    # --- GUI COMPONENTS ---
    "waybar"
    "swaync"
    "rofi-wayland"
    "kitty"
    "dolphin"
    "ark"                     # Archives (unzip/zip from GUI)
    "kio-admin"               # Root access in Dolphin
    "kio-extras"              # Network protocols & extra thumbnails
    "ffmpegthumbs"            # Video thumbnails
    "kdegraphics-thumbnailers" # Image thumbnails
    "ffmpegthumbnailer"       # Rofi video thumbnails
    "baloo-widgets"           # Information panel
    "taglib"                  # File metadata
    
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
    "imagemagick"             # Required by cliphist-rofi for image previews
    "wtype"                   # Required by cliphist-rofi for auto-typing
    
    # --- SCREENSHOT & WALLPAPER ---
    "grim"
    "slurp"
    "swappy"
    "swaybg"
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
    "ttf-orbitron"
    "noto-fonts-emoji"
    "obsidian-icon-theme"
    "starship"
    "fastfetch"
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
        aur_install "$pkg"
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
