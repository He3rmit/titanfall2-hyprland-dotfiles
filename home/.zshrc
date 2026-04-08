# TITANFALL ZSH CONFIGURATION
# ---------------------------

# 1. 🚀 Starship Prompt (The HUD)
# This loads your starship.toml from ~/.config/starship.toml
eval "$(starship init zsh)"

# 2. ⚡ Plugins (The "Fish Behavior")
# These give you the grey ghost-text and red/green command highlighting.
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /usr/share/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh

# 3. ⌨️ Keybinds (Fix Up/Down Arrow History Search)
bindkey -e
bindkey '^[[A' history-substring-search-up
bindkey '^[[B' history-substring-search-down

# 4. 🛠️ History Settings
setopt HIST_IGNORE_ALL_DUPS  # Don't record duplicates
setopt SHARE_HISTORY         # Share history between terminals
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history

# 5. 📂 Environment
export EDITOR=nvim
export TERMINAL=kitty
export BROWSER=firefox

# Add your custom scripts to PATH so you can run them from anywhere
export PATH=$HOME/.local/bin:$HOME/.config/hypr/scripts:$PATH

# 6. 🔗 Universal Aliases (Safe on ALL Arch-based distros)
alias battery='upower -i /org/freedesktop/UPower/devices/battery_BAT0'
alias wifi='nmtui'
alias refresh='hyprctl reload && killall waybar; waybar & disown && killall swaync && rm -rf ~/.cache/swaync && swaync & disown'
alias logout='hyprctl dispatch exit'

# 7. 🔒 Secrets (gitignored, loaded if present)
[[ -f ~/.secrets.sh ]] && source ~/.secrets.sh

# 8. 🎨 Personal Overrides (machine-specific, gitignored)
# Put your aliases, distro-specific tools, and custom exports in ~/.zshrc.local
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local

# 9. 🖼️ Fetch on Terminal Open
fastfetch
