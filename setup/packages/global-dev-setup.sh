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
    bash "$CURRENT_DIR/zsh-global.sh" --force
else
    bash "$CURRENT_DIR/zsh-global.sh"
fi

if [ $? -ne 0 ]; then
    echo "❌ Error: ZSH installation failed"
    exit 1
fi

# Step 2: Install NVM globally
echo ""
echo "Step 2/3: Installing NVM globally..."
echo "---------------------------------------------------"
bash "$CURRENT_DIR/nvm-global.sh"

if [ $? -ne 0 ]; then
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
echo "  ✓ NPM"
echo "  ✓ Yarn"
echo ""
echo "🔧 Configuration:"
echo "  ✓ All new users will automatically have access"
echo "  ✓ Templates created in /etc/skel/"
echo "  ✓ Profile scripts in /etc/profile.d/"
echo ""
echo "📌 Next Steps:"
echo ""
echo "1. To apply ZSH to current user:"
echo "   sudo setup-zsh-user"
echo "   sudo chsh -s /bin/zsh \$USER"
echo ""
echo "2. To use NVM in current session:"
echo "   source /etc/profile.d/nvm.sh"
echo "   nvm --version"
echo ""
echo "3. For new users:"
echo "   They will automatically have ZSH and NVM configured!"
echo ""
echo "4. To setup existing users:"
echo "   sudo setup-zsh-user [username]"
echo "   sudo chsh -s /bin/zsh [username]"
echo ""
echo "======================================================="
echo ""

