#!/bin/bash

# Install and configure ZSH globally for all users (including new users)

echo "================================"
echo "Setting up ZSH globally for all users"
echo "================================"
echo ""

# Install ZSH
REQUIRED_PKG="zsh"
PKG_OK=$(dpkg-query -W --showformat='${Status}\n' $REQUIRED_PKG 2>/dev/null | grep "install ok installed")

if [ "" = "$PKG_OK" ]; then
    echo "Installing ZSH..."
    sudo apt-get update
    sudo apt-get install -y $REQUIRED_PKG git curl
else
    echo "✓ ZSH already installed"
fi

# Install Oh-My-Zsh globally
OH_MY_ZSH_GLOBAL="/usr/share/oh-my-zsh"

if [ ! -d "$OH_MY_ZSH_GLOBAL" ]; then
    echo ""
    echo "Installing Oh-My-Zsh globally at $OH_MY_ZSH_GLOBAL..."
    sudo git clone https://github.com/robbyrussell/oh-my-zsh.git "$OH_MY_ZSH_GLOBAL"
    sudo chmod -R 755 "$OH_MY_ZSH_GLOBAL"
else
    echo "✓ Oh-My-Zsh already installed globally"
fi

# Install ZSH plugins globally
echo ""
echo "Installing ZSH plugins..."

# Fast Syntax Highlighting
if [ ! -d "$OH_MY_ZSH_GLOBAL/custom/plugins/fast-syntax-highlighting" ]; then
    echo "Installing Fast Syntax Highlighting..."
    sudo git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git \
        "$OH_MY_ZSH_GLOBAL/custom/plugins/fast-syntax-highlighting"
else
    echo "✓ Fast Syntax Highlighting already installed"
fi

# ZSH Autosuggestions
if [ ! -d "$OH_MY_ZSH_GLOBAL/custom/plugins/zsh-autosuggestions" ]; then
    echo "Installing ZSH Autosuggestions..."
    sudo git clone https://github.com/zsh-users/zsh-autosuggestions.git \
        "$OH_MY_ZSH_GLOBAL/custom/plugins/zsh-autosuggestions"
else
    echo "✓ ZSH Autosuggestions already installed"
fi

# Powerlevel10k theme
if [ ! -d "$OH_MY_ZSH_GLOBAL/custom/themes/powerlevel10k" ]; then
    echo "Installing Powerlevel10k theme..."
    sudo git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
        "$OH_MY_ZSH_GLOBAL/custom/themes/powerlevel10k"
else
    echo "✓ Powerlevel10k theme already installed"
fi

# Set permissions
sudo chmod -R 755 "$OH_MY_ZSH_GLOBAL"

# Create global zshrc template from home/.zshrc
echo ""
echo "Creating global ZSH configuration template from home/.zshrc..."

# Get the script directory to find home/.zshrc
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
HOME_ZSHRC="$SCRIPT_DIR/home/.zshrc"
HOME_ZSH_ALIASES="$SCRIPT_DIR/home/.zsh_aliases"

if [ ! -f "$HOME_ZSHRC" ]; then
    echo "⚠️  Warning: $HOME_ZSHRC not found, using default config"
    sudo tee /etc/skel/.zshrc > /dev/null <<'EOF'
# Path to your oh-my-zsh installation.
export ZSH="/usr/share/oh-my-zsh"

# Set name of the theme to load
ZSH_THEME="powerlevel10k/powerlevel10k"

# Plugins
plugins=(
    git
    docker
    docker-compose
    npm
    node
    zsh-autosuggestions
    fast-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

# User configuration
export LANG=en_US.UTF-8
export EDITOR='vim'

# Load aliases
[ -f ~/.zsh_aliases ] && source ~/.zsh_aliases

# NVM configuration
export NVM_DIR="/usr/local/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
EOF
else
    # Copy and modify .zshrc to use global paths
    sudo cp "$HOME_ZSHRC" /etc/skel/.zshrc

    # Update paths in .zshrc to use global installation
    sudo sed -i 's|export ZSH="$HOME/.oh-my-zsh"|export ZSH="/usr/share/oh-my-zsh"|g' /etc/skel/.zshrc

    # Update NVM path to global
    sudo sed -i 's|export NVM_DIR="$HOME/.nvm"|export NVM_DIR="/usr/local/nvm"|g' /etc/skel/.zshrc

    # Comment out the direct plugin source lines since they're already in global location
    sudo sed -i 's|^source ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh|# source ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh # Loaded via plugins|g' /etc/skel/.zshrc
    sudo sed -i 's|^source ~/.oh-my-zsh/custom/plugins/fast-syntax-highlighting/F-Sy-H.plugin.zsh|# source ~/.oh-my-zsh/custom/plugins/fast-syntax-highlighting/F-Sy-H.plugin.zsh # Loaded via plugins|g' /etc/skel/.zshrc

    echo "✓ Created /etc/skel/.zshrc from home/.zshrc with global paths"
fi

# Copy .zsh_aliases if exists
if [ -f "$HOME_ZSH_ALIASES" ]; then
    sudo cp "$HOME_ZSH_ALIASES" /etc/skel/.zsh_aliases
    echo "✓ Copied home/.zsh_aliases to /etc/skel/.zsh_aliases"
else
    echo "⚠️  Warning: $HOME_ZSH_ALIASES not found, skipping"
fi

# Copy p10k config from home/.p10k.zsh
echo ""
echo "Copying Powerlevel10k configuration from home/.p10k.zsh..."

HOME_P10K="$SCRIPT_DIR/home/.p10k.zsh"

if [ -f "$HOME_P10K" ]; then
    sudo cp "$HOME_P10K" /etc/skel/.p10k.zsh
    echo "✓ Copied home/.p10k.zsh to /etc/skel/.p10k.zsh"
else
    echo "⚠️  Warning: $HOME_P10K not found, creating basic config"
    sudo tee /etc/skel/.p10k.zsh > /dev/null <<'EOF'
# Powerlevel10k instant prompt
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Basic Powerlevel10k configuration
typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=(
  dir                     # current directory
  vcs                     # git status
)

typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=(
  status                  # exit code of the last command
  command_execution_time  # duration of the last command
  background_jobs         # presence of background jobs
  context                 # user@hostname
  time                    # current time
)

typeset -g POWERLEVEL9K_MODE='nerdfont-complete'
typeset -g POWERLEVEL9K_ICON_PADDING=moderate
EOF
    echo "✓ Created basic /etc/skel/.p10k.zsh template"
fi

# Update current user's zshrc if exists
CURRENT_USER_HOME="$HOME"
if [ -f "$CURRENT_USER_HOME/.zshrc" ]; then
    echo ""
    echo "Backing up current user's .zshrc to .zshrc.backup..."
    cp "$CURRENT_USER_HOME/.zshrc" "$CURRENT_USER_HOME/.zshrc.backup.$(date +%Y%m%d_%H%M%S)"

    # Check if using old oh-my-zsh path
    if grep -q "ZSH=.*/.oh-my-zsh" "$CURRENT_USER_HOME/.zshrc"; then
        echo "Updating current user's .zshrc to use global Oh-My-Zsh..."
        sed -i 's|export ZSH=.*|export ZSH="/usr/share/oh-my-zsh"|g' "$CURRENT_USER_HOME/.zshrc"
        echo "✓ Updated current user's .zshrc"
    fi
fi

# Function to setup ZSH for existing user
echo ""
echo "Creating helper script for existing users..."

sudo tee /usr/local/bin/setup-zsh-user > /dev/null <<'EOF'
#!/bin/bash
# Setup ZSH for existing user

USER_TO_SETUP="${1:-$USER}"
USER_HOME=$(eval echo "~$USER_TO_SETUP")

echo "Setting up ZSH for user: $USER_TO_SETUP"
echo "Home directory: $USER_HOME"

if [ ! -d "$USER_HOME" ]; then
    echo "Error: User home directory not found"
    exit 1
fi

# Backup existing zshrc
if [ -f "$USER_HOME/.zshrc" ]; then
    cp "$USER_HOME/.zshrc" "$USER_HOME/.zshrc.backup.$(date +%Y%m%d_%H%M%S)"
    echo "✓ Backed up existing .zshrc"
fi

# Copy templates
cp /etc/skel/.zshrc "$USER_HOME/.zshrc"
cp /etc/skel/.p10k.zsh "$USER_HOME/.p10k.zsh" 2>/dev/null || true
cp /etc/skel/.zsh_aliases "$USER_HOME/.zsh_aliases" 2>/dev/null || true

# Fix permissions
chown "$USER_TO_SETUP:$USER_TO_SETUP" "$USER_HOME/.zshrc"
[ -f "$USER_HOME/.p10k.zsh" ] && chown "$USER_TO_SETUP:$USER_TO_SETUP" "$USER_HOME/.p10k.zsh"
[ -f "$USER_HOME/.zsh_aliases" ] && chown "$USER_TO_SETUP:$USER_TO_SETUP" "$USER_HOME/.zsh_aliases"

echo "✓ ZSH configured for $USER_TO_SETUP"
echo ""
echo "To set ZSH as default shell for $USER_TO_SETUP, run:"
echo "  sudo chsh -s /bin/zsh $USER_TO_SETUP"
EOF

sudo chmod +x /usr/local/bin/setup-zsh-user

echo ""
echo "================================"
echo "✓ ZSH global setup completed!"
echo "================================"
echo ""
echo "📌 Oh-My-Zsh installed at: $OH_MY_ZSH_GLOBAL"
echo "📌 All new users will have ZSH automatically configured"
echo ""
echo "📌 To setup ZSH for existing users, run:"
echo "   sudo setup-zsh-user [username]"
echo "   sudo chsh -s /bin/zsh [username]"
echo ""
echo "📌 To setup ZSH for current user:"
echo "   sudo setup-zsh-user"
echo "   sudo chsh -s /bin/zsh $USER"
echo ""
echo "📌 Installed plugins:"
echo "   - fast-syntax-highlighting"
echo "   - zsh-autosuggestions"
echo "   - powerlevel10k theme"
echo ""

