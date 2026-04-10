# Titanfall Pilot Desktop (Arch + Hyprland) 🚀

This is a fully declarative, hardware-agnostic ricing project for Arch Linux and Hyprland, heavily inspired by a Titanfall "Pilot HUD" aesthetic. It has evolved into a production-ready, multi-host desktop environment with dynamic display scaling, international layout support, and a glassmorphic notification center.

## 🔗 Repository Notice
This is the **HARDENED** version of the Titanfall Dotfiles (v3.4.0+). It features a completely modular architecture where your personal settings are kept private and machine-specific.

## 🛠️ Key Features
- **Display Agnostic**: Built-in scaling wizard (1.0x to 2.0x) ensures the HUD looks perfect on everything from 1080p desktops to 4K laptops.
- **International Ready**: Strategic move to positional keybinds ensures your workspaces work natively on **QWERTY, AZERTY, QWERTZ**, and more.
- **Pure Modularity**: Separation of `core/` logic and `hosts/` personalization folders.
- **Master UI Switcher**: Hot-swap between 5 Waybar layouts and 5 CSS styles at runtime via Rofi.
- **Glassmorphic HUD**: Custom SwayNC control panel with quick-action grid and Pywal dynamic theming.
- **Modular Installer**: A `gum`-based interactive TUI that handles dependencies, stowing, and first-run hardware calibration.

---

## ⚡ Quick Start

```bash
# 1. Clone the repository
git clone https://github.com/He3rmit/dotfiles.git ~/dotfiles
cd ~/dotfiles

# 2. Run the interactive deployment terminal
./installer/install.sh
```

During installation, you will be prompted to create a **Host Profile**. This profile stores your machine's specific monitor, scaling, and layout preferences in a private folder that is automatically ignored by Git.

---

## 📖 Documentation
- [MANUAL.md](MANUAL.md) — The Operator's Manual (Keybinds, HUD Controls, Configuration).
- [LICENSE](LICENSE) — Licensed under GNU GPL v3.0.

---

## 📂 Repository Structure

```
dotfiles/
├── core/              # SHARED LOGIC (The "Chassis")
│   ├── waybar/        # 5 Layouts x 5 Styles
│   ├── swaync/        # The Pilot HUD Notification Center
│   ├── rofi/          # Launchers, Switchers, Grid themes
│   └── wallpapers/    # Library of Static & Video wallpapers
├── hosts/             # PERSONALIZATION (The "Neuro-Link")
│   ├── _template/     # Starter kits (Laptop / Desktop)
│   └── [your-host]/   # Your private configs (PROTECED & IGNORED)
├── hyprland/          # MODULARWM CONFIG
│   ├── modules/       # Keybinds, Visuals, Autostart, Modules
│   └── hyprland.conf  # Main entry point
├── home/              # SHELL ENVIRONMENT (.zshrc, .bashrc)
└── installer/         # TUI DEPLOYMENT ENGINE
```

---

## 🏅 Release History

### [v1.0.0] — The "Golden Release" (Current)
- **Hardening**: Completely scrubbed absolute paths for total portability.
- **Display Agnostic**: Implemented dynamic monitor detection and scaling factor wizard.
- **Internationalization**: Switched to physical keycodes for layout-independent navigation.
- **Privacy Lock**: Implemented host-folder git-protection and GPL-3.0 licensing.

---

**Pilot, your Titan is standing by. Deploy at your own risk.** 🦾