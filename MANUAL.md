# 🚀 Titanfall Pilot HUD — Operator Manual (v3.4.0)

> *"The HUD is modular. The Pilot is agnostic. The Titan is universal."*

## 1. Core Architecture — Modular vs. Personal
Starting with v3.4.0, your desktop is split into two layers:
- **Core (`core/`, `hyprland/`)**: The shared "Engine" and "Visuals" that everyone uses.
- **Host (`hosts/`)**: Your machine's specific "Neuro-Link". This stores your private monitor resolution, scaling preferences, and hardware-specific keybinds.

---

## 2. Keybind Reference ($mainMod = SUPER)

### 🧩 Positional Workspace Logic (International Support)
The workspace binds in this framework are **Positional**, not character-based. This means:
- The **1st key** in your number row always opens Workspace 1.
- The **2nd key** opens Workspace 2.
- **Result**: Whether you use **QWERTY (1, 2, 3)**, **AZERTY (&, é, ")**, or **QWERTZ**, the physical movement of your hand remains identical.

| Key (Positional) | Action |
|:---|:---|
| `Super + [Key 1-0]` | Switch to workspace 1-10 |
| `Super + [Key F1-F12]` | Switch to special workspaces 11-22 |
| `Super + Shift + [Key 1-0]` | Move window to workspace |

### 🛰️ The Pilot HUD (SwayNC) — `Super + N`
The **Pilot HUD** is your mission control. It features:
- **WiFi Indicator**: Click to toggle (managed by `nm-applet`).
- **Power Modes**: Balanced / Power Saver / Performance.
- **Tactile Feedback**: Subtle opacity pulse on all grid buttons.

---

## 3. Display Calibration & Scaling
Your monitor rule is now **Dynamic**. 

### How to Scale the UI:
If your icons look too small or too big, do not edit `hyprland.conf`. 
1.  Run the installer: `./installer/install.sh`
2.  Select your existing profile.
3.  The **Monitor Wizard** will suggest a scaling factor (1.0 for 1080p, 1.5+ for 4K).
4.  This updates `~/.config/hypr/modules/monitor.conf` automatically.

---

## 4. Host Profile Customization
Your private machine folder (`hosts/your-machine/`) is the only place you should make hardware-specific edits.

| File | Audit Purpose |
|:---|:---|
| `profile.conf` | **Identity**: Monitor name, Scaling factor, Layout choice. |
| `hypr-host.conf` | **Hardware**: Touchpad sensitivity, Laptop lid rules. |
| `user-keybinds.conf` | **Personal**: Add your own app shortcuts here; they will never be overwritten by updates. |

---

## 5. Security & Git Hygiene
This framework is built with **Privacy-by-Default**.
- **Excluded Folders**: All folders in `hosts/` (except `_template`) are in `.gitignore`. 
- **Safe Commits**: You can push your fork of this project to GitHub/GitLab without leaking your private machine name or desktop sensitivity.
- **Secrets**: Files like `home/.secrets.sh` and `home/.zshrc.local` are strictly local.

---

## 6. Maintenance & Troubleshooting

### Updating the HUD
If you pull the latest core code from the repository:
1. Run `./installer/install.sh`
2. Select **01-stow-configs**.
3. This will re-link the new core logic while preserving your private host settings.

### Desktop Entry Cache
The autostart sequence runs `kbuildsycoca6` to automatically refresh your Rofi application entries. This is protected by a safety check—if you don't use KDE, the command is simply ignored.

---

**Protocol 3: Protect the Pilot.** 🦾 🛡️ 
