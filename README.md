# Titanfall Pilot Desktop (Arch + Hyprland)

This is a custom ricing project for Arch Linux and Hyprland, heavily inspired by a Titanfall "Pilot HUD" aesthetic. What started as an experimental first attempt at ricing using the [Hyprland Wiki](https://wiki.hypr.land) tutorials has evolved into a fully modular, stable desktop setup.

## Features
- **Window Manager:** Hyprland
- **Bar:** Waybar (Titanfall Pilot theme)
- **App Launcher:** Rofi-Wayland
- **Terminal:** Kitty
- **Shell:** Zsh + Starship
- **Dashboard:** Wtfutil
- **Login Manager:** SDDM (Astronaut theme with custom Cinematic Video)

---

## Installation
The installation process uses an interactive, `gum`-based TUI. It supports installing on either a "laptop" or "desktop", and intelligently detects if you're installing over a base Arch environment or alongside an existing KDE Plasma installation.

```bash
git clone https://github.com/your-username/dotfiles.git ~/dotfiles
cd ~/dotfiles
./installer/install.sh
```

---

## Milestones & Version History

### [v2.1.0] - UI Quality of Life & Wallpaper Restructure (Current)
- Implemented a fully interactive, Rofi-based manual wallpaper selector (Grid UI).
- Combined all static and live wallpapers into a single `core/wallpapers/library` directory.
- Retired the automated `mpvpaper-pool.sh` script in favor of the manual persistent selector.
- Completely redesigned the Rofi Application Launcher (drun) to feature a modern, wide-search grid layout inspired by JaKooLit.

### [v2.0.0] - Modular Installer Rewrite
- Replaced the monolithic `install.sh` with a modular `installer/` directory structure.
- Introduced `gum` for a high-quality Terminal UI and interactive deployment.
- Completely overhauled `00-dependencies.sh` to auto-detect "Naked Arch" vs "KDE Fallback" installations to ensure required UI daemons (like `polkit-kde-agent`) are installed.
- Transitioned stow methodology to dynamic directory creation to prevent config folding conflicts.

### [v1.5.0] - HUD Overhaul
- Major "Pilot HUD" and Workspace config rework.
- Separated monolithic configurations into modular files.
- Introduced DND states and specific Waybar tweaks.

### [v1.0.0] - Stable Release
- First fully working, stable version.
- Hardware configurations settled (Bluetooth, Trackpad fixes, Battery upower script).
- Solidified the SwayNC styling and Waybar structure.

### [v0.1.0] - Inception
- First time attempting Linux ricing in Hyprland.
- Initial migrations and early config tweaks.