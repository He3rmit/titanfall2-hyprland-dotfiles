#!/bin/bash

# --- PILOT UTILITIES ---

# Print a formatted step using gum (if available), otherwise fallback to standard echo
print_step() {
    if command -v gum &> /dev/null; then
        gum style --foreground 212 --bold "$1"
    else
        echo -e "\033[1;35m$1\033[0m"
    fi
}

print_success() {
    if command -v gum &> /dev/null; then
        gum style --foreground 46 --bold "✅ $1"
    else
        echo -e "\033[1;32m✅ $1\033[0m"
    fi
}

print_warning() {
    if command -v gum &> /dev/null; then
        gum style --foreground 214 --bold "⚠️  $1"
    else
        echo -e "\033[1;33m⚠️  $1\033[0m"
    fi
}

print_error() {
    if command -v gum &> /dev/null; then
        gum style --foreground 196 --bold "❌ $1"
    else
        echo -e "\033[1;31m❌ $1\033[0m"
    fi
}

# Safety Protocol: Backup existing files before symlinking
safe_link() {
    local source="$1"
    local target="$2"
    mkdir -p "$(dirname "$target")"

    if [ -L "$target" ]; then
        # It's already a symlink, just replace it
        rm "$target"
    elif [ -e "$target" ]; then
        # It's a real file, back it up
        print_warning "Existing file detected at $target. Creating backup (.bak)"
        mv "$target" "${target}.bak"
    fi
    ln -s "$source" "$target"
    # echo "Linked: $source -> $target"
}

# HUD Verification: Check for necessary fonts to avoid "?" icons
check_fonts() {
    local font_name="ShureTechMono Nerd Font"
    if ! fc-list : family | grep -iq "$font_name"; then
        print_error "WARNING: $font_name not found. Workspace icons may show as '?'"
        echo "💡 Hint: Install the font from your dotfiles or AUR."
    else
        print_success "Font $font_name verified. HUD icons nominal."
    fi
}

# Ensure Sudo is active for the script execution
keep_sudo_alive() {
    print_step "Initializing Pilot Authorization..."
    sudo -v
    while true; do 
        sudo -n true
        sleep 60
        kill -0 "$$" || exit
    done 2>/dev/null &
}
