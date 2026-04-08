# 🚀 Titanfall Pilot HUD — Operator Manual

> *"Your dotfiles are your armor. Know every piece of it."*

## Table of Contents
1. [Installation](#installation)
2. [Keybind Reference](#keybind-reference)
3. [Waybar Switcher](#waybar-switcher)
4. [Pilot HUD (SwayNC)](#pilot-hud-swaync)
5. [Wallpaper System](#wallpaper-system)
6. [Rofi Launcher Guide](#rofi-launcher-guide)
7. [Clipboard Manager](#clipboard-manager)
8. [Host Modularity](#host-modularity)
9. [Installer Modules](#installer-modules)
10. [Updating & Stowing](#updating--stowing)

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
| `Super + Alt + E` | Wallpaper Effects (ImageMagick filters) |
| `Super + Alt + B` | Waybar Switcher (layout + style + direction) |

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
| `Super + N` | Toggle Pilot HUD (SwayNC) |
| `Super + B` | Cycle Waybar power profiles |
| `Ctrl + Shift + S` | Screenshot → Annotate (Swappy) |
| `Print` | Screenshot to clipboard |
| `Super + Shift + V` | Clipboard Manager |
| `Touchpad Toggle Key` | Toggle touchpad on/off |

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

## Waybar Switcher

Open with `Super + Alt + B`. A Rofi menu lets you hot-swap between layouts, styles, and bar orientations without restarting Hyprland.

### Layouts (Position & Module Density)

| Layout | Position | Description |
|---|---|---|
| 1-Sidebar-Compact | Left/Right | Slim sidebar with icon-only modules |
| 2-Topbar-Detailed | Top | Full labels (CPU: 8%, RAM: 3.3G, WLAN: 75%) |
| 3-Topbar-Minimal | Top | Clean, minimal top bar |
| 4-Bottom-Dock | Bottom | macOS-style dock at the bottom |
| 5-Sidebar-Minimal | Left/Right | Ultra-minimal vertical strip |

### Styles (CSS Themes)

| Style | Description |
|---|---|
| 1-Titan-Glass | Glassmorphic panels with Pywal-tinted borders |
| 2-Flat-Material | Solid background, material design |
| 3-Neon-Border | Glowing neon outlines |
| 4-Cyberpunk-Glitch | Edgy, high-contrast with gritty textures |
| 5-Glass-Pill | Rounded translucent pills (floating modules) |

All styles are dynamically themed via Pywal. Changing your wallpaper re-colors everything.

### Change Direction
The switcher also offers a **"Change Direction"** option to flip the current layout between horizontal (`top`/`bottom`) and vertical (`left`/`right`).

---

## Pilot HUD (SwayNC)

The notification center is re-branded as the **Pilot HUD** — a glassmorphic control panel with quick actions, media controls, and notification history.

Open with `Super + N`.

### Quick Action Grid

| Button | Action |
|---|---|
| 📶 WiFi | Toggle WiFi on/off |
| 🔷 Bluetooth | Toggle Bluetooth on/off |
| ⚡ Power Modes | Cycle between Balanced / Power Saver / Performance |
| 🔊 Volume | Open PavuControl |
| 📊 System Monitor | Open system monitor |
| 📸 Screenshot | Take a screenshot |
| 🔉 Audio Effects | Launch EasyEffects |
| 📈 Resource Monitor | Launch BTOP |
| 📡 WiFi Hotspot | Launch Linux WiFi Hotspot |

### Interaction Design
- **Click Feedback:** All buttons have a subtle opacity dim on press (`0.08s` snap-back) for immediate tactile confirmation.
- **Notifications:** Toggling WiFi/Bluetooth/Power Modes sends a `notify-send` confirmation with the new state.
- **Notification Behavior:** When the HUD is open, incoming notifications route directly into the history panel. When closed, they pop up normally as toast notifications.
- **Calendar:** Click the Waybar clock module to open `gsimplecal`.

### Glassmorphism
The HUD panel uses a frosted glass effect via Hyprland's layer rules defined in `visuals.conf`. The blur and transparency are Pywal-aware.

---

## Wallpaper System

### Wallpaper Selector — `Super + Alt + W`
Opens a Rofi grid of all available wallpapers with thumbnail previews.

- Wallpapers live in `~/.config/wallpapers/library/`
- Supported formats: `.jpg`, `.png`, `.mp4`, `.webm`, `.mkv`

| Type | Backend | Notes |
|---|---|---|
| Static (jpg/png) | `swaybg` | Zero CPU/GPU when idle |
| Video (mp4/webm) | `mpvpaper` | Uses VA-API hardware decoding (~5% CPU) |

The current wallpaper is remembered in `~/.config/wallpapers/.current_wallpaper` and restored automatically on login.

> 💡 On battery, switch to a static wallpaper to save ~10-20% battery life by allowing the GPU to deep-sleep.

### Wallpaper Effects — `Super + Alt + E`
Opens a Rofi menu to apply ImageMagick filters to the currently active wallpaper:

- Blur, Grayscale, Vignette, Sepia, and more
- Effects are applied to a cached copy — your original wallpaper is never modified
- The base wallpaper is always preserved for re-application or removal of effects
- Pywal re-extracts colors after each effect change

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

| Key | Action | With Multi-Select (`Shift + Enter`) |
|---|---|---|
| `Enter` | Copy selected entry to clipboard | Copies **first** checked item |
| `Alt + P` | Preview image natively | Opens **first** checked image fullscreen |
| `Alt + Delete` | Delete this single entry | Deletes **all** checked items |
| `Alt + Shift + Delete` | Wipe entire history | Wipes entire history |
| `Alt + T` | Auto-type the entry | Auto-types **all** checked items sequentially |
| `Alt + O` | Open the entry as a URL | Opens **all** checked URLs in browser simultaneously |
| `Alt + E` | Edit the entry in nano | Stitches **all** checked items into one editable file |

**How to Bulk Select:** Use `Shift + Enter` to check multiple items before hitting an Alt action key.

> 💡 **Auto-Type (`Alt + T`)** bypasses "Block Paste" fields on websites by simulating real keystrokes instead of pasting from clipboard.

---

## Master Utility Console (pilot-control)

Because this repository can be deployed across a wide variety of Arch Linux systems (like Garuda or CachyOS), the environment uses a master utility script called `pilot-control` to manage system-level overrides. 

You can run this command directly from anywhere in your terminal.

### SDDM Cinematic Override
The Titanfall SDDM Login screen uses a "High-Priority" configuration override to force the video to play, which can prevent standard KDE System Settings from changing the theme. 

If you want to return control to standard KDE/Plasma menus, you can use `pilot-control` to disengage the Titanfall override.

| Command | Action |
|:---|:---|
| `pilot-control sddm --status` | Checks if the Cinematic Priority Override is active. |
| `pilot-control sddm --restore` | **Disengages** the override. The login screen will revert to system defaults (like Breeze or Garuda's native theme). |
| `pilot-control sddm --engage` | **Engages** the override. Forces the Titanfall Cinematic video back to the login screen. |

---

## Host Modularity

The dotfiles support multiple machine profiles. Shared configs live in `core/`, while machine-specific overrides live in `hosts/{laptop,desktop}`.

### What Each Host Overrides

| Config | Laptop | Desktop |
|---|---|---|
| Waybar `config.jsonc` | Includes battery, backlight | No battery or backlight modules |
| SwayNC `config.json` | Backlight slider + touchpad toggle | No backlight, no touchpad |
| Hyprland `host.conf` | Touchpad settings, lid switch | Monitor layout, no touchpad |

### How It Works
1. The installer asks for your deployment target (`laptop` or `desktop`).
2. `01-stow-configs` symlinks **core/** first, then overlays the selected **host/** on top.
3. Host-specific files override their core counterparts where they exist.

> 💡 To add a new host (e.g., `htpc`), create a `hosts/htpc/` directory with only the files you need to override.

---

## Installer Modules

Run `bash installer/install.sh` and select which modules to deploy.

| Module | What it does |
|---|---|
| `00-dependencies` | Installs all required system packages via Pacman/AUR |
| `01-stow-configs` | Symlinks all dotfiles into `~/.config` using GNU Stow |
| `02-audio-rescue` | **[DEVICE SPECIFIC]** Fixes Intel Tiger Lake SST audio and mic priorities |
| `03-sddm-theme` | Installs the Astronaut login screen theme |

> 🧪 **Operational Insight: What is Audio-Rescue?**
>
> This module is a **Hardware-Specific Fix** for the Pilot's laptop (Intel Tiger Lake SST). It forces the system into `pro-audio` mode and gives the internal microphone a high-priority "lock."
>
> **For other Pilot machines:**
> - **Wait for glitches:** If your audio is working fine, **SKIP THIS.**
> - **The "Cold Start" Trick:** Even on other hardware, running this performs a "Wireplumber Cold Start" (stops daemon -> wipes cache -> restarts), which can fix general crackling or switching bugs. Otherwise, do not use this if it doesn't help your audio stack.

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
