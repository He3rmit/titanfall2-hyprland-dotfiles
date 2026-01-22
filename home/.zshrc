# TITANFALL ZSH CONFIGURATION
# ---------------------------

# 1. 🚀 Starship Prompt (The HUD)
# This loads your starship.toml from ~/.config/starship.toml
eval "$(starship init zsh)"

# 2. ⚡ Plugins (The "Fish Behavior")
# These give you the grey ghost-text and red/green command highlighting.
# (Make sure you ran: sudo pacman -S zsh-autosuggestions zsh-syntax-highlighting zsh-history-substring-search)
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

# 5. 📂 Environment & Path
export EDITOR=nvim
export TERMINAL=kitty
export BROWSER=firefox

# Add your custom scripts to PATH so you can run them from anywhere
export PATH=$HOME/.local/bin:$HOME/dotfiles/core/hypr/scripts:$PATH

# 6. 🔗 Aliases
alias ll='ls -alF'
alias update='sudo pacman -Syu'
alias grubup='sudo update-grub'
alias tarnow='shutdown -h now'
alias unlock='sudo rm /var/lib/pacman/db.lck'
alias batteryhealth='upower -i /org/freedesktop/UPower/devices/battery_BAT0'
alias wifi='nmtui'
alias clearcache= 'kbuildsycoca6 --noincremental' 
alias autorefresh='kbuildsycoca6 --noincremental  && killall waybar && waybar && killall swaync && swaync && swaync-client -rs && swaync-client -R'

# 7. 🎨 Optional Fetch
fastfetch
