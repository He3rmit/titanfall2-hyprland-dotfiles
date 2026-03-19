# 🚀 Titanfall Pilot HUD — Operator Manual

> *"Your dotfiles are your armor. Know every piece of it."*

## Table of Contents
1. [Installation](#installation)
2. [Keybind Reference](#keybind-reference)
3. [Rofi Launcher Guide](#rofi-launcher-guide)
4. [Clipboard Manager](#clipboard-manager)
5. [Wallpaper System](#wallpaper-system)
6. [Installer Modules](#installer-modules)
7. [Updating & Stowing](#updating--stowing)

---

## Installation

```bash
git clone https://github.com/He3rmit/dotfiles.git ~/dotfiles
cd ~/dotfiles/installer
bash install.sh
```

The installer will guide you through selecting a deployment target (`laptop` or `desktop`) and choosing which modules to run.

---

## Keybind Reference

> **`$mainMod` = `SUPER` (Windows Key)**

### Cluster 1 — The Launchpad

| Keybind | Action |
|---|---|
| `Super + Q` | Open Terminal (Kitty) |
| `Super + E` | Open File Manager (Dolphin) |
| `Super + R` | App Launcher (Rofi — Apps / Files / Win) |
| `Super + Ctrl + R` | Raw Command Runner (Rofi — Executables) |
| `Super + Alt + W` | Wallpaper Selector |

### Cluster 2 — The Buckets (Special Workspaces)

| Keybind | Action |
|---|---|
| `Super + S` | Toggle Standard workspace |
| `Super + W` | Toggle Work workspace |
| `Super + H` | Toggle Hobby workspace |
| `Super + G` | Toggle Gaming workspace |
| `Super + T` | Toggle Tools workspace |
| `Super + Shift + [S/W/H/G/T]` | Move focused window to that workspace |

### Cluster 3 — Window State

| Keybind | Action |
|---|---|
| `Super + C` | Close active window |
| `Super + V` | Toggle floating |
| `Super + F` | Fullscreen |
| `Super + P` | Pseudo-tile |
| `Super + J` | Toggle split direction |

### Cluster 4 — System

| Keybind | Action |
|---|---|
| `Super + L` | Lock screen (Hyprlock) |
| `Power Button` | Logout menu (Wlogout) |
| `Super + N` | Toggle notification center (SwayNC) |
| `Super + B` | Cycle Waybar power profiles |
| `Ctrl + Shift + S` | Screenshot → Annotate (Swappy) |
| `Print` | Screenshot to clipboard |
| `Super + Shift + V` | Clipboard Manager |

### Media Keys

| Keybind | Action |
|---|---|
| `Super + I / O` | Mic Volume Up / Down |
| `XF86AudioMicMute` | Toggle Mic Mute |
| `XF86Audio*` | Volume, Play/Pause, Next, Prev |

### Navigation

| Keybind | Action |
|---|---|
| `Super + Arrow Keys` | Move window focus |
| `Super + 1-9, 0` | Switch to workspace 1-10 |
| `Super + F1-F12` | Switch to workspace 11-22 |
| `Super + Shift + 1-0` | Move window to workspace |
| `Super + Scroll` | Cycle workspaces |

---

## Rofi Launcher Guide

### App Launcher — `Super + R`
Opens a grid of `.desktop` applications with three tabs:

| Tab | What it shows |
|---|---|
| **Apps** | All installed GUI applications |
| **Files** | Keyboard-driven file browser |
| **Win** | All open windows (switch between them) |

**Tips:**
- Typing filters the current tab instantly.
- `Enter` launches the highlighted item.
- `Shift + Enter` opens any app in a Kitty terminal window.

### Raw Command Runner — `Super + Ctrl + R`
A slim drop-down bar for running raw system commands and executables directly.

- `Enter` runs the command in the background.
- `Shift + Enter` runs it inside a Kitty terminal.

> ⚠️ Shell aliases (defined in `.zshrc`) do **not** work here — type the real binary name.

---

## Clipboard Manager

Open with `Super + Shift + V`.

| Key | Action |
|---|---|
| `Enter` | Copy selected entry to clipboard |
| `Alt + Delete` | Delete this single entry |
| `Alt + Shift + Delete` | **Wipe entire history** |
| `Alt + T` | Auto-type the entry (simulates keyboard input) |
| `Alt + O` | Open the entry as a URL in your browser |
| `Alt + E` | Edit the entry in a Kitty + nano popup |

> 💡 **Auto-Type (`Alt + T`)** bypasses "Block Paste" fields on websites by simulating real keystrokes instead of pasting from clipboard.

---

## Wallpaper System

Open the selector with `Super + Alt + W`.

- Wallpapers live in `~/.config/wallpapers/library/`
- Supported formats: `.jpg`, `.png`, `.mp4`, `.webm`, `.mkv`

| Type | Backend | Notes |
|---|---|---|
| Static (jpg/png) | `swaybg` | Zero CPU/GPU when idle |
| Video (mp4/webm) | `mpvpaper` | Uses VA-API hardware decoding (~5% CPU) |

The current wallpaper is remembered in `~/.config/wallpapers/.current_wallpaper` and restored automatically on login.

> 💡 On battery, switch to a static wallpaper to save ~10-20% battery life by allowing the GPU to deep-sleep.

---

## Installer Modules

Run `bash installer/install.sh` and select which modules to deploy.

| Module | What it does |
|---|---|
| `00-dependencies` | Installs all required system packages via Pacman/AUR |
| `01-stow-configs` | Symlinks all dotfiles into `~/.config` using GNU Stow |
| `02-audio-rescue` | Deploys Wireplumber config and restarts the audio daemon |
| `03-sddm-theme` | Installs the Astronaut login screen theme |

---

## Updating & Stowing

After editing a dotfile in the repo, you don't need to copy it anywhere. GNU Stow creates symlinks, so edits are live instantly.

To re-stow everything (e.g. after adding new files):
```bash
cd ~/dotfiles/installer
bash install.sh
# Select only: 01-stow-configs
```

To check what is currently stowed:
```bash
ls -la ~/.config/hypr/
# Symlinks will point back into ~/dotfiles/
```

To commit your changes:
```bash
cd ~/dotfiles
git add .
git commit -m "feat: describe your change here"
```
