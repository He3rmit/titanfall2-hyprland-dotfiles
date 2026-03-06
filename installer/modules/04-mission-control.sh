#!/bin/bash
# ==============================================================================
# MODULE: 04-mission-control.sh
# Purpose: Deploys Wtfutil dependencies and initializes the secure secrets file.
# ==============================================================================

source "$INSTALLER_DIR/scripts/utils.sh"

print_step "Deploying Mission Control Dashboard..."

# 1. Dependency Verification
if ! command -v wtfutil &> /dev/null; then
    print_warning "wtfutil not found."
    aur_install wtfutil-bin
    print_success "wtfutil installed."
else
    print_success "wtfutil is installed."
fi

# 2. SECRETS PROTOCOL: Ensure the local secrets file exists for API keys
print_step ">> Verifying Secure Secrets Vault..."

if [ ! -f "$HOME/.secrets.sh" ]; then
    print_warning "No existing secrets vault found. Initializing empty vault at ~/.secrets.sh..."
    
    # Create the template
    echo "#!/bin/bash" > "$HOME/.secrets.sh"
    echo "# --------------------------------------------------------------------------" >> "$HOME/.secrets.sh"
    echo "# TITANFALL PILOT SECRETS FILE" >> "$HOME/.secrets.sh"
    echo "# This file is ignored by Git. Safe for private keys and local overrides." >> "$HOME/.secrets.sh"
    echo "# --------------------------------------------------------------------------" >> "$HOME/.secrets.sh"
    echo "" >> "$HOME/.secrets.sh"
    echo "# OpenWeatherMap API Key for the 'wtfutil' dashboard" >> "$HOME/.secrets.sh"
    echo "# export WTF_OWM_API_KEY=\"your_api_key_here\"" >> "$HOME/.secrets.sh"
    
    # Ensure only the user can read/write this file for security
    chmod 600 "$HOME/.secrets.sh"
    
    print_error "MISSION DATA MISSING: Please add your OpenWeather key to ~/.secrets.sh"
else
    # Vault exists, verify permissions just to be safe
    chmod 600 "$HOME/.secrets.sh"
    print_success "Secrets vault located at ~/.secrets.sh and permissions secured."
fi

print_success "Mission Control Protocol Complete."
