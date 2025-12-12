#!/bin/bash

# Install and configure ZSH globally for all users (including new users)

# Parse arguments
FORCE_UPDATE=false
if [ "${1:-}" = "-f" ] || [ "${1:-}" = "--force" ]; then
    FORCE_UPDATE=true
fi

echo "================================"
echo "Setting up ZSH globally for all users"
if [ "$FORCE_UPDATE" = true ]; then
    echo "⚡ FORCE MODE ENABLED ⚡"
fi
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
# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes

#ZSH_THEME="robbyrussell"
ZSH_THEME="powerlevel10k/powerlevel10k"

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
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

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
[ -f ~/.zsh_aliases ] && source ~/.zsh_aliases

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

export NVM_DIR="/usr/local/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
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

HOME_P10K="$SCRIPT_DIR/home/.p10k.zsh.default"

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

# Force update all existing users if --force flag is set
if [ "$FORCE_UPDATE" = true ]; then
    echo ""
    echo "================================"
    echo "⚡ Force updating dotfiles for all existing users..."
    echo "================================"
    echo ""
    
    # Get all normal users (UID >= 1000 and UID < 65534)
    ALL_USERS=$(awk -F: '$3 >= 1000 && $3 < 65534 {print $1}' /etc/passwd)
    
    for username in $ALL_USERS; do
        user_home=$(eval echo "~$username")
        
        if [ -d "$user_home" ]; then
            echo "→ Updating dotfiles for user: $username ($user_home)"
            
            # Backup existing files
            if [ -f "$user_home/.zshrc" ]; then
                sudo cp "$user_home/.zshrc" "$user_home/.zshrc.backup.$(date +%Y%m%d_%H%M%S)" 2>/dev/null || true
            fi
            
            # Copy new dotfiles
            sudo cp /etc/skel/.zshrc "$user_home/.zshrc" 2>/dev/null || true
            sudo cp /etc/skel/.p10k.zsh "$user_home/.p10k.zsh" 2>/dev/null || true
            sudo cp /etc/skel/.zsh_aliases "$user_home/.zsh_aliases" 2>/dev/null || true
            
            # Fix ownership
            sudo chown "$username:$username" "$user_home/.zshrc" 2>/dev/null || true
            sudo chown "$username:$username" "$user_home/.p10k.zsh" 2>/dev/null || true
            sudo chown "$username:$username" "$user_home/.zsh_aliases" 2>/dev/null || true
            
            echo "  ✓ Updated dotfiles for $username"
        else
            echo "  ⚠️  Home directory not found for $username, skipping..."
        fi
    done
    
    echo ""
    echo "✅ Force update completed for all existing users!"
    echo ""
fi

echo ""
echo "================================"
echo "✓ ZSH global setup completed!"
echo "================================"
echo ""
echo "📌 Oh-My-Zsh installed at: $OH_MY_ZSH_GLOBAL"
echo "📌 All new users will have ZSH automatically configured"
echo ""
if [ "$FORCE_UPDATE" = false ]; then
    echo "📌 To setup ZSH for existing users, run:"
    echo "   sudo setup-zsh-user [username]"
    echo "   sudo chsh -s /bin/zsh [username]"
    echo ""
    echo "📌 To setup ZSH for current user:"
    echo "   sudo setup-zsh-user"
    echo "   sudo chsh -s /bin/zsh $USER"
    echo ""
fi
echo "📌 Installed plugins:"
echo "   - fast-syntax-highlighting"
echo "   - zsh-autosuggestions"
echo "   - powerlevel10k theme"
echo ""

