#!/bin/bash

# Setup development environment globally for all users
# This script will install and configure NVM, Node.js, NPM, Yarn, and ZSH

# Parse arguments
FORCE_UPDATE=false
if [ "${1:-}" = "-f" ] || [ "${1:-}" = "--force" ]; then
    FORCE_UPDATE=true
fi

echo "======================================================="
echo "  Global Development Environment Setup"
echo "======================================================="
echo ""
echo "This script will install and configure:"
echo "  ✓ ZSH with Oh-My-Zsh"
echo "  ✓ NVM (Node Version Manager)"
echo "  ✓ Node.js (LTS version)"
echo "  ✓ NPM (Node Package Manager)"
echo "  ✓ Yarn (Package Manager)"
echo ""
echo "All configurations will be available for:"
echo "  - Current user"
echo "  - All new users created in the future"
echo ""
if [ "$FORCE_UPDATE" = true ]; then
    echo "⚡ FORCE MODE: Will update dotfiles for all existing users"
    echo ""
fi
echo "======================================================="
echo ""

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then
    echo "⚠️  Warning: This script should be run with sudo for full functionality"
    echo "Some features may not work without root privileges."
    echo ""
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

CURRENT_DIR=$(dirname "$(readlink -f "$0")")

# Step 1: Install ZSH globally
echo ""
echo "Step 1/3: Installing ZSH globally..."
echo "---------------------------------------------------"
if [ "$FORCE_UPDATE" = true ]; then
    if ! bash "$CURRENT_DIR/zsh-global.sh" --force; then
        echo "❌ Error: ZSH installation failed"
        exit 1
    fi
else
    if ! bash "$CURRENT_DIR/zsh-global.sh"; then
        echo "❌ Error: ZSH installation failed"
        exit 1
    fi
fi

# Step 2: Install NVM globally
echo ""
echo "Step 2/3: Installing NVM globally..."
echo "---------------------------------------------------"
if ! bash "$CURRENT_DIR/nvm-global.sh"; then
    echo "❌ Error: NVM installation failed"
    exit 1
fi

# Step 3: Install Yarn globally
echo ""
echo "Step 3/3: Installing Yarn globally..."
echo "---------------------------------------------------"
if ! bash "$CURRENT_DIR/yarn-global.sh"; then
    echo "❌ Error: Yarn installation failed"
    exit 1
fi

# Step 4: Setup permissions for existing users
echo ""
echo "Step 4/4: Configuring permissions for existing users..."
echo "---------------------------------------------------"

# Function to add user to developers group
add_user_to_developers() {
    local username="$1"

    # Skip system users (UID < 1000)
    local uid
    uid=$(id -u "$username" 2>/dev/null)
    if [ -z "$uid" ] || [ "$uid" -lt 1000 ]; then
        return
    fi

    # Check if user is already in developers group
    if groups "$username" | grep -q "\bdevelopers\b"; then
        echo "  ✓ User '$username' already in developers group"
    else
        echo "  → Adding user '$username' to developers group..."
        sudo usermod -aG developers "$username"
        echo "  ✓ User '$username' added to developers group"
    fi
}

# Create developers group if not exists
if ! getent group developers > /dev/null 2>&1; then
    echo "Creating 'developers' group..."
    sudo groupadd developers
fi

# Add current user to developers group
CURRENT_USER="${SUDO_USER:-$(whoami)}"
add_user_to_developers "$CURRENT_USER"

# Optionally add all existing non-system users
if [ "$FORCE_UPDATE" = true ]; then
    echo ""
    echo "Adding all existing users to developers group..."
    while IFS=: read -r username _ uid _ _ home shell; do
        # Skip if UID < 1000 (system users) or if home doesn't exist
        if [ "$uid" -ge 1000 ] && [ -d "$home" ]; then
            add_user_to_developers "$username"
        fi
    done < /etc/passwd
fi

# Final summary
echo ""
echo "======================================================="
echo "  ✅ Global Development Environment Setup Complete!"
echo "======================================================="
echo ""
echo "📦 Installed Components:"
echo "  ✓ ZSH + Oh-My-Zsh (globally at /usr/share/oh-my-zsh)"
echo "  ✓ NVM (globally at /usr/local/nvm)"
echo "  ✓ Node.js LTS"
echo "  ✓ NPM (global packages at /usr/local/nvm/npm-global)"
echo "  ✓ Yarn"
echo ""
echo "🔧 Configuration:"
echo "  ✓ 'developers' group created for shared access"
echo "  ✓ Current user added to developers group"
echo "  ✓ All new users will automatically have access"
echo "  ✓ Templates created in /etc/skel/"
echo "  ✓ Profile scripts in /etc/profile.d/"
echo ""
echo "🔐 Permissions:"
echo "  ✓ Users in 'developers' group can install npm/yarn packages globally"
echo "  ✓ Users in 'developers' group can install Node versions via nvm"
echo ""
echo "📌 Next Steps:"
echo ""
echo "1. To apply changes in current session (REQUIRED):"
echo "   newgrp developers"
echo "   source /etc/profile.d/nvm.sh"
echo ""
echo "2. Or logout and login again to apply group membership"
echo ""
echo "3. To use NVM:"
echo "   nvm --version"
echo "   nvm install 22    # Install Node.js version 22"
echo "   nvm use 22        # Use Node.js version 22"
echo ""
echo "4. For new users:"
echo "   They will automatically have ZSH and NVM configured!"
echo "   Add them to developers group:"
echo "   sudo usermod -aG developers <username>"
echo ""
echo "5. To setup existing users:"
echo "   sudo usermod -aG developers <username>"
echo "   sudo setup-zsh-user <username>"
echo "   sudo chsh -s /bin/zsh <username>"
echo ""
echo "======================================================="
echo ""

