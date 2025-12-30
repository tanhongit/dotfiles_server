#!/bin/bash

# Install Yarn globally for all users

echo "================================"
echo "Setting up Yarn globally for all users"
echo "================================"
echo ""

# Check if NVM is installed
NVM_DIR="/usr/local/nvm"
if [ ! -d "$NVM_DIR" ]; then
    echo "❌ Error: NVM not found at $NVM_DIR"
    echo "Please install NVM first using nvm-global.sh"
    exit 1
fi

# Load NVM for current session
export NVM_DIR="/usr/local/nvm"
# shellcheck disable=SC1091
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Check if npm is available
if ! command -v npm &>/dev/null; then
    echo "❌ Error: NPM not found"
    echo "Please make sure Node.js is installed via NVM"
    exit 1
fi

# Install Yarn globally using npm
if command -v yarn &>/dev/null; then
    echo "✓ Yarn already installed"
    yarn --version
else
    echo "Installing Yarn globally via npm..."
    if npm install -g yarn; then
        echo "✓ Yarn installed successfully"
        yarn --version
    else
        echo "❌ Error: Failed to install Yarn"
        exit 1
    fi
fi

# Enable Corepack (modern way to manage Yarn/pnpm)
echo ""
echo "Enabling Corepack for Yarn management..."
if command -v corepack &>/dev/null; then
    corepack enable
    echo "✓ Corepack enabled"
else
    echo "⚠️  Corepack not available in this Node.js version"
fi

echo ""
echo "================================"
echo "✓ Yarn global setup completed!"
echo "================================"
echo ""
echo "📌 Yarn installed globally via npm"
echo "📌 All users can use yarn command"
echo ""
echo "📌 Verify installation:"
echo "   yarn --version"
echo ""
echo "📌 Common yarn commands:"
echo "   yarn init          - Create a new project"
echo "   yarn add [pkg]     - Add a package"
echo "   yarn install       - Install dependencies"
echo "   yarn upgrade       - Upgrade dependencies"
echo ""

