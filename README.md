# Titanfall Pilot Desktop (Arch + Hyprland)

This is a custom ricing project for Arch Linux and Hyprland, heavily inspired by a Titanfall "Pilot HUD" aesthetic. What started as an experimental first attempt at ricing using the [Hyprland Wiki](https://wiki.hypr.land) tutorials has evolved into a fully modular, multi-host desktop environment with dynamic theming, a Waybar layout/style switcher, and a glassmorphic notification center.

## Features
- **Window Manager:** Hyprland (modular config split across `keybinds`, `visuals`, `windowrules`, `input`, `autostart`)
- **Bar:** Waybar — 5 layouts × 5 styles, switchable at runtime via Rofi
- **Notification Center:** SwayNC — Glassmorphic "Pilot HUD" with quick-action grid, media controls, and Pywal theming
- **App Launcher:** Rofi-Wayland (wide-search grid layout)
- **Wallpaper Engine:** Swaybg (static) / Mpvpaper (video) + ImageMagick effects pipeline
- **Global Theming:** Pywal — one wallpaper change re-themes Waybar, Rofi, SwayNC, and Kitty
- **Terminal:** Kitty + Zsh + Starship
- **Login Manager:** SDDM (Astronaut theme with custom cinematic video)
- **Host Modularity:** Separate profiles for `laptop` and `desktop` with shared core configs

---

## Installation
The installation process uses an interactive, `gum`-based TUI. It supports installing on either a "laptop" or "desktop", and intelligently detects if you're installing over a base Arch environment or alongside an existing KDE Plasma installation.

```bash
git clone https://github.com/He3rmit/dotfiles.git ~/dotfiles
cd ~/dotfiles
./installer/install.sh
```

> 📖 See [MANUAL.md](MANUAL.md) for the full operator manual — keybinds, wallpaper system, clipboard manager, Waybar switcher, and Pilot HUD controls.

---

## Repository Structure

```
dotfiles/
├── core/              # Shared configs (waybar, swaync, rofi, kitty, etc.)
│   ├── waybar/
│   │   ├── common.jsonc       # All module definitions
│   │   ├── layouts/           # 5 layout positions (sidebar, topbar, dock)
│   │   ├── styles/            # 5 CSS themes (glass, material, neon, etc.)
│   │   └── scripts/           # Peripheral monitor, power cycle
│   ├── swaync/
│   │   ├── config.json        # Quick-action grid, widget hierarchy
│   │   ├── style.css          # Glassmorphic HUD styling (Pywal-linked)
│   │   └── scripts/           # pilot-control.sh, hud-launcher.sh
│   ├── rofi/                  # App launcher, clipboard, wallpaper grid themes
│   ├── wallpapers/            # Library of static + video wallpapers
│   └── ...                    # kitty, starship, fastfetch, wlogout, sddm
├── hosts/
│   ├── laptop/                # Laptop-specific overrides (backlight, touchpad)
│   └── desktop/               # Desktop-specific overrides (no battery, no backlight)
├── hyprland/                  # Hyprland modules (keybinds, visuals, input, autostart)
├── home/                      # Shell configs (.zshrc, .bashrc)
├── installer/                 # gum-based TUI installer with modular deployment
│   ├── install.sh
│   ├── modules/               # 00-dependencies, 01-stow, 02-audio, 03-sddm
│   └── scripts/               # Utility functions
├── README.md
└── MANUAL.md
```

---

## Milestones & Version History

### [v2.5.0] - Host Modularity Rework (Current)
- Completely restructured into `core/` + `hosts/{laptop,desktop}` architecture.
- Host-specific overrides for Waybar, SwayNC, and Hyprland configs.
- Desktop profile strips laptop-only hardware (backlight, battery, touchpad toggle).
- Dependency manifest updated with `gsimplecal` and `linux-wifi-hotspot`.

#### Post-v2.5.0 Fixes
- Replaced SwayNC's native calendar with a Waybar clock integration (gsimplecal).
- Added WiFi Hotspot quick-action button to the Pilot HUD grid.
- Fixed missing system tray (kded6 `statusnotifierwatcher` module race condition).
- Restored flush-to-top Waybar margin (`0 10 0 10`).
- Redesigned tactile feedback — retired persistent toggle glows for a universal subtle opacity-dimming `:active` pulse.
- Removed extraneous box-shadow from the Glass Pill Waybar style.

### [v2.4.0] - SwayNC Quick Actions
- Expanded the Pilot HUD quick-action grid with WiFi toggle, Bluetooth toggle, Power Modes, Volume control, System Monitor, Screenshot, and Hotspot launcher.
- SwayNC now follows Waybar's layout configuration for consistent positioning.
- Cleaned up leftover hardcoded colors in favor of Pywal variables.

### [v2.3.0] - Waybar Layout & Style Switcher
- Introduced the Waybar Switcher (`Super + Alt + B`) — a Rofi menu to hot-swap between 5 layouts and 5 CSS styles at runtime.
- Added the Wallpaper Effects pipeline (`Super + Alt + E`) — apply ImageMagick filters (blur, grayscale, vignette, etc.) to the active wallpaper.
- All Waybar layouts support both horizontal (top/bottom) and vertical (left/right) orientations.

### [v2.2.0] - Reworked Clipboard Manager
- Uses the same utilities as before, but more modern.
- Has instructions on how to use the clipboard more effectively.
- Reworked the clipboard in favor of simplicity and ease of use.
- Uses keybinds to adhere actions.

### [v2.1.0] - UI Quality of Life & Wallpaper Restructure
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