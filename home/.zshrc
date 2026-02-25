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
alias filelist='ls -alF' # long listing with file types
alias upgrade='paru -Syu --noconfirm && flatpak update -y --noninteractive && paru -Sc --noconfirm && paccache -r -u && flatpak remove --unused -y --noninteractive && paru -Rns (pacman -Qdtq)$ --noconfirm && paru -c --noconfirm' #Use with caution, as it will automatically update and remove packages without asking for confirmation. The & at the end runs the command in the background, allowing you to continue using the terminal while it updates.
alias limeup='sudo limine-update' # change parameters depending on the type of boot loader used
alias unlock='sudo rm /var/lib/pacman/db.lck' #when the pacman database is locked, use this to unlock it. Use with caution.
alias battery='upower -i /org/freedesktop/UPower/devices/battery_BAT0' # check battery status
alias wifi='nmtui' # Network Manager TUI, a terminal-based Wi-Fi manager
alias refresh='hyprctl reload && killall waybar; waybar & disown && killall swaync && rm -rf ~/.cache/swaync && swaync & disown' # reload Hyprland, restart Waybar, and restart swaync (the status notifier daemon) to apply changes to your config without restarting your entire session. Use with caution, as it will kill all instances of Waybar and swaync, which may cause issues if you have multiple instances running.
alias manga='manga-tui -p weebcentral' #
alias anime='ani-cli'
alias logout='hyprctl dispatch exit'  # log out of your session immediately, use with caution
alias xampp='sudo /opt/lampp/manager-linux-x64.run' #xampp manager

# 7. 🎨 Optional Fetch
fastfetch
