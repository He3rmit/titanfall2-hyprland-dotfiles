#!/bin/bash
# ==============================================================================
# TITANFALL PILOT HUD — EJECT PROTOCOL
# Purpose: Safely remove all dotfile symlinks, caches, overrides, and
#          optionally uninstall Hyprland-specific packages while preserving
#          system-critical components.
# ==============================================================================

cd "$(dirname "$0")" || exit 1
INSTALLER_DIR=$(pwd)
DOTFILES_DIR=$(dirname "$INSTALLER_DIR")
source "$INSTALLER_DIR/scripts/utils.sh"

# ── 0. ENSURE GUM ──────────────────────────────────────────────────────────────
if ! command -v gum &> /dev/null; then
    echo "gum is required for this UI. Install it with: paru -S gum"
    exit 1
fi

clear

# ── 1. SPLASH SCREEN ──────────────────────────────────────────────────────────
gum style \
    --border double \
    --border-foreground 196 \
    --foreground 196 \
    --bold \
    --margin "1 4" \
    --padding "1 8" \
    "███████╗     ██╗███████╗ ██████╗████████╗" \
    "██╔════╝     ██║██╔════╝██╔════╝╚══██╔══╝" \
    "█████╗       ██║█████╗  ██║        ██║   " \
    "██╔══╝  ██   ██║██╔══╝  ██║        ██║   " \
    "███████╗╚█████╔╝███████╗╚██████╗   ██║   " \
    "╚══════╝ ╚════╝ ╚══════╝ ╚═════╝   ╚═╝   "

gum style \
    --foreground 244 \
    --align center \
    --margin "0 4" \
    "PILOT HUD  //  EJECT PROTOCOL  //  v2.0"

echo ""

gum style \
    --foreground 214 \
    --bold \
    --margin "0 4" \
    "⚠️  This will remove Titanfall dotfile configs from your system." \
    "   You can optionally remove Hyprland-specific packages too."

echo ""

# ── 2. AUTHORIZATION ──────────────────────────────────────────────────────────
gum style --foreground 214 --bold "[ PILOT AUTHORIZATION ]"
keep_sudo_alive

# ── 3. MODULE SELECTION ───────────────────────────────────────────────────────
echo ""
gum style --foreground 51 --bold "Select Eject Modules:"
gum style --foreground 244 \
    "  Unstow Configs           — Remove all symlinks from ~/.config and ~/" \
    "  Clean Pywal Cache        — Remove ~/.cache/wal/ color cache" \
    "  Clean Wireplumber        — Remove audio config overrides & restart daemon" \
    "  Clean SDDM Theme         — Remove cinematic login override (requires sudo)" \
    "  Uninstall Packages       — Remove Hyprland-specific packages (safe only)" \
    "  Full Eject               — All of the above"
echo ""
gum style --foreground 244 "(SPACE to select, ENTER to confirm)"
echo ""

MODULES=$(gum choose --no-limit \
    "Unstow Configs" \
    "Clean Pywal Cache" \
    "Clean Wireplumber" \
    "Clean SDDM Theme" \
    "Uninstall Packages" \
    "Full Eject")

if [ -z "$MODULES" ]; then
    print_warning "No modules selected. Eject aborted."
    exit 0
fi

# Check if Full Eject was selected — enable all flags
FULL_EJECT=false
if echo "$MODULES" | grep -q "Full Eject"; then
    FULL_EJECT=true
fi

echo ""
gum style --foreground 196 --bold "You selected:"
echo "$MODULES" | while read -r line; do
    echo "  🔸 $line"
done
echo ""

if ! gum confirm --prompt.foreground 196 "Initiate Eject Protocol?"; then
    print_warning "Eject aborted by Pilot."
    exit 0
fi

echo ""

# ── 4. HELPER: Remove symlink safely ─────────────────────────────────────────
remove_link() {
    local target="$1"
    if [ -L "$target" ]; then
        rm "$target"
        echo "  🗑️  Removed symlink: $target"
    elif [ -f "$target" ]; then
        rm "$target"
        echo "  🗑️  Removed file: $target"
    fi
}

# ── 5. UNSTOW CONFIGS ────────────────────────────────────────────────────────
if echo "$MODULES" | grep -q "Unstow Configs" || [ "$FULL_EJECT" = true ]; then
    print_step ">> Ejecting Stowed Configurations..."

    # A. Unstow the 'home' package (~/.zshrc, ~/.local/bin/pilot-control)
    cd "$DOTFILES_DIR" || exit 1
    stow -D -t "$HOME" home 2>/dev/null
    echo "  🗑️  Unstowed: home (.zshrc, pilot-control)"

    # B. Unstow the 'core' package (~/.config/*)
    stow -D -t "$HOME/.config" core 2>/dev/null
    echo "  🗑️  Unstowed: core (fastfetch, kitty, rofi, swaync, waybar, wlogout, starship)"

    # C. Unstow the 'hyprland' package (~/.config/hypr/*)
    stow -D -t "$HOME/.config/hypr" hyprland 2>/dev/null
    echo "  🗑️  Unstowed: hyprland (modules, scripts)"

    # D. Remove safe_link targets (explicit symlinks not managed by stow)
    print_step ">> Removing explicit symlinks..."
    remove_link "$HOME/.config/hypr/host.conf"
    remove_link "$HOME/.config/kitty/host.conf"
    remove_link "$HOME/.config/swaync/config.json"
    remove_link "$HOME/.config/waybar/config.jsonc"
    remove_link "$HOME/.config/waybar/style.css"
    remove_link "$HOME/.zshrc.local"

    # E. Remove generated files (not symlinks, created by bootstrap)
    print_step ">> Removing generated state files..."
    remove_link "$HOME/.config/hypr/touchpad.conf"
    remove_link "$HOME/.config/hypr/modules/colors.conf"
    remove_link "$HOME/.config/wallpapers/.current_wallpaper"
    rm -f "$HOME/.config/wallpapers/.current_effect_image"

    # F. Restore a minimal .zshrc so the terminal doesn't break
    if [ ! -f "$HOME/.zshrc" ]; then
        print_step ">> Restoring minimal .zshrc fallback..."
        cat > "$HOME/.zshrc" << 'FALLBACK'
# Minimal fallback .zshrc (Titanfall dotfiles were uninstalled)
# Feel free to customize this or replace it entirely.

# History
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
setopt HIST_IGNORE_ALL_DUPS
setopt SHARE_HISTORY

# Basic prompt
PROMPT='%F{cyan}%n@%m%f:%F{blue}%~%f$ '

export EDITOR=nano
export PATH=$HOME/.local/bin:$PATH
FALLBACK
        echo "  ✅ Created minimal ~/.zshrc fallback"
    fi

    print_success "Configs ejected."
fi

# ── 6. CLEAN PYWAL CACHE ─────────────────────────────────────────────────────
if echo "$MODULES" | grep -q "Clean Pywal Cache" || [ "$FULL_EJECT" = true ]; then
    print_step ">> Purging Pywal color cache..."
    if [ -d "$HOME/.cache/wal" ]; then
        rm -rf "$HOME/.cache/wal"
        echo "  🗑️  Removed: ~/.cache/wal/"
    else
        echo "  ℹ️  No Pywal cache found. Skipping."
    fi

    # Clean clipboard thumbnails too
    rm -rf /tmp/cliphist-thumbnails 2>/dev/null

    print_success "Pywal cache purged."
fi

# ── 7. CLEAN WIREPLUMBER ─────────────────────────────────────────────────────
if echo "$MODULES" | grep -q "Clean Wireplumber" || [ "$FULL_EJECT" = true ]; then
    print_step ">> Removing Wireplumber overrides..."

    WP_DIR="$HOME/.config/wireplumber/wireplumber.conf.d"
    remove_link "$WP_DIR/50-common-priorities.conf"
    remove_link "$WP_DIR/51-host-rescue.conf"

    # Restart daemon so it falls back to system defaults
    print_step ">> Restarting Wireplumber with system defaults..."
    systemctl --user stop wireplumber 2>/dev/null
    rm -rf ~/.local/state/wireplumber/* 2>/dev/null
    systemctl --user start wireplumber 2>/dev/null

    print_success "Wireplumber restored to system defaults."
fi

# ── 8. CLEAN SDDM THEME ──────────────────────────────────────────────────────
if echo "$MODULES" | grep -q "Clean SDDM Theme" || [ "$FULL_EJECT" = true ]; then
    print_step ">> Disengaging Cinematic SDDM Protocol..."

    # A. Remove priority override
    if [ -L "/etc/sddm.conf.d/00-theme.conf" ] || [ -f "/etc/sddm.conf.d/00-theme.conf" ]; then
        sudo rm -f "/etc/sddm.conf.d/00-theme.conf"
        echo "  🗑️  Removed: /etc/sddm.conf.d/00-theme.conf"
    fi

    # B. Remove copied cinematic content from the theme directory
    POSSIBLE_THEMES=(
        "/usr/share/sddm/themes/sddm-astronaut-theme"
        "/usr/share/sddm/themes/sddm-theme-astronaut"
    )

    for theme_dir in "${POSSIBLE_THEMES[@]}"; do
        if [ -d "$theme_dir" ]; then
            if [ -f "$theme_dir/Movies/titanfall_intro_cinematic.mp4" ]; then
                sudo rm -f "$theme_dir/Movies/titanfall_intro_cinematic.mp4"
                echo "  🗑️  Removed: $theme_dir/Movies/titanfall_intro_cinematic.mp4"
            fi
            if [ -f "$theme_dir/theme.conf.user" ]; then
                sudo rm -f "$theme_dir/theme.conf.user"
                echo "  🗑️  Removed: $theme_dir/theme.conf.user"
            fi
            if [ -f "$theme_dir/Themes/astronaut.conf.user" ]; then
                sudo rm -f "$theme_dir/Themes/astronaut.conf.user"
                echo "  🗑️  Removed: $theme_dir/Themes/astronaut.conf.user"
            fi
        fi
    done

    print_success "SDDM reverted to system defaults."
fi

# ── 9. UNINSTALL PACKAGES ────────────────────────────────────────────────────
if echo "$MODULES" | grep -q "Uninstall Packages" || [ "$FULL_EJECT" = true ]; then
    print_step ">> Analyzing packages for safe removal..."

    # ╔════════════════════════════════════════════════════════════════════════╗
    # ║ SAFETY PHILOSOPHY                                                     ║
    # ║                                                                       ║
    # ║ Packages are split into two categories:                               ║
    # ║                                                                       ║
    # ║ REMOVABLE — Hyprland/rice-specific tools that serve no purpose        ║
    # ║             outside of this dotfile setup. Safe to yank.              ║
    # ║                                                                       ║
    # ║ PROTECTED — System-critical packages shared with other DEs,           ║
    # ║             audio/network stacks, base utilities, and core fonts.     ║
    # ║             These are NEVER touched by the uninstaller.               ║
    # ║                                                                       ║
    # ║ Additionally, pacman will naturally refuse to remove any package      ║
    # ║ that is a dependency of something else still installed.               ║
    # ╚════════════════════════════════════════════════════════════════════════╝

    # Packages that are ONLY useful for this Hyprland rice
    REMOVABLE_PACKAGES=(
        # Hyprland ecosystem (the WM and its satellites)
        "hyprland"
        "xdg-desktop-portal-hyprland"
        "xwaylandvideobridge"
        "hypridle"
        "hyprlock"
        "hyprpicker"
        "hyprsunset"

        # Wayland-specific bars, launchers, and panels
        "waybar"
        "swaync"
        "rofi"
        "wlogout"

        # Wayland clipboard stack
        "wl-clipboard"
        "cliphist"
        "wtype"

        # Wayland screenshot tools
        "grim"
        "slurp"
        "swappy"

        # Wayland wallpaper engines
        "swaybg"
        "mpvpaper"

        # Rice-specific theming
        "python-pywal"
        "xorg-xrdb"
        "nwg-look"
        "obsidian-icon-theme"
        "ttf-orbitron"

        # Rice-specific shell tools
        "starship"
        "fastfetch"

        # Calendar widget (only used in Waybar)
        "gsimplecal"

        # SDDM theme deps (only needed for the Astronaut cinematic)
        "qt5-graphicaleffects"
        "qt5-quickcontrols2"
        "qt5-svg"
    )

    # ── PROTECTED PACKAGES (NEVER REMOVED) ────────────────────────────────
    # These are intentionally NOT in the removable list:
    #
    # SYSTEM CRITICAL:
    #   pipewire, pipewire-pulse, wireplumber  — Audio stack (used by everything)
    #   networkmanager                         — Network (system-critical)
    #   bluez, bluez-utils                     — Bluetooth stack (system-wide)
    #   upower                                 — Power management (used by DEs)
    #   power-profiles-daemon                  — CPU governor (system-wide)
    #   xdg-desktop-portal, xdg-desktop-portal-gtk — Used by GNOME/KDE too
    #   qt5-wayland, qt6-wayland               — Used by any Qt app on Wayland
    #   libnotify                              — Used by many applications
    #   xdg-user-dirs                          — Creates ~/Documents, ~/Downloads etc.
    #   xorg-xhost                             — Used by many X11 apps
    #   polkit-kde-agent                       — Auth dialogs (needed by KDE too)
    #   gnome-keyring, sddm                    — Login/secrets (system-level)
    #   stow                                   — Generic utility
    #
    # SHARED APPLICATIONS:
    #   kitty, alacritty                       — Terminal emulators (user may prefer)
    #   dolphin, ark, gvfs                     — File manager stack (KDE ecosystem)
    #   kio-admin, kio-extras                  — KDE I/O plugins
    #   ffmpegthumbs, kdegraphics-thumbnailers — Thubnail engines (KDE)
    #   baloo-widgets, taglib                  — KDE metadata
    #   mpv, ffmpeg, ffmpegthumbnailer         — General multimedia
    #   imagemagick                            — General image processing
    #   btop, pavucontrol                      — System monitor & audio mixer
    #   brightnessctl, playerctl               — Hardware control (generic)
    #   easyeffects, blueman                   — Audio/BT GUIs (user preference)
    #   linux-wifi-hotspot                     — Networking tool
    #   jq, unzip, wget                        — Core utilities
    #   nss-mdns                               — DNS resolution
    #
    # SHARED FONTS:
    #   ttf-sharetech-mono-nerd                — Terminal font (user may use elsewhere)
    #   ttf-jetbrains-mono-nerd                — Dev font (used by IDEs)
    #   ttf-nerd-fonts-symbols                 — Icon glyphs (used by many apps)
    #   noto-fonts-emoji                       — System emoji
    #   adwaita-icon-theme, breeze-icons       — GNOME/KDE fallback icons
    #
    # SHELL:
    #   zsh, zsh-autosuggestions, etc.          — User's shell (may still be default)

    # Build the list of packages that are actually installed
    INSTALLED_REMOVABLE=()
    for pkg in "${REMOVABLE_PACKAGES[@]}"; do
        if pacman -Qi "$pkg" &>/dev/null; then
            INSTALLED_REMOVABLE+=("$pkg")
        fi
    done

    if [ ${#INSTALLED_REMOVABLE[@]} -eq 0 ]; then
        print_success "No removable Hyprland packages found. Nothing to do."
    else
        echo ""
        gum style --foreground 214 --bold "The following Hyprland-specific packages will be removed:"
        echo ""
        for pkg in "${INSTALLED_REMOVABLE[@]}"; do
            echo "  📦 $pkg"
        done
        echo ""

        gum style --foreground 244 \
            "System packages (pipewire, networkmanager, bluez, kitty, dolphin," \
            "zsh, fonts, etc.) will NOT be touched."
        echo ""

        # Second confirmation gate specifically for package removal
        if gum confirm --prompt.foreground 196 "Proceed with package removal?"; then
            print_step ">> Removing Hyprland-specific packages..."

            # Use pacman -Rns to remove packages AND their orphaned dependencies.
            # pacman will automatically refuse to remove anything that is still
            # required by another installed package.
            sudo pacman -Rns --noconfirm "${INSTALLED_REMOVABLE[@]}" 2>&1 | while read -r line; do
                echo "  $line"
            done

            # Rebuild font cache after font removal
            print_step ">> Rebuilding font cache..."
            fc-cache -fv > /dev/null 2>&1

            print_success "Hyprland packages removed."
        else
            print_warning "Package removal skipped."
        fi
    fi
fi

# ── 10. SIGN-OFF ──────────────────────────────────────────────────────────────
echo ""
gum style \
    --border rounded \
    --border-foreground 214 \
    --foreground 214 \
    --bold \
    --padding "1 4" \
    --margin "1 2" \
    "EJECT COMPLETE" \
    "" \
    "All Titanfall configs have been removed." \
    "System-critical packages remain untouched." \
    "" \
    "Protocol 3: Protect the Pilot."
