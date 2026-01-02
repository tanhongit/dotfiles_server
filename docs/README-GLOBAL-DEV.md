# Global Development Setup Guide

## Overview

This guide explains how to setup and manage global development tools (NVM, NPM, Yarn, ZSH) for multiple users on a server.

## Problem Statement

When installing NVM, NPM, and Yarn globally, users often encounter permission issues:
- Cannot install Node.js versions without sudo
- Cannot install npm/yarn packages globally without sudo
- Each user needs their own NVM installation (wasteful)

## Solution: Shared Development Environment with Group Permissions

Our setup creates a shared development environment using the `developers` group:

```
/usr/local/nvm/              # NVM installation (shared)
├── nvm.sh                   # NVM script
├── npm-global/              # NPM global packages (shared)
│   ├── bin/
│   └── lib/
├── yarn-global/             # Yarn global packages (shared)
└── yarn-cache/              # Yarn cache (shared)
```

All directories are owned by `root:developers` with `775` permissions and SGID bit set.

## Installation

### Step 1: Install Global Dev Environment

```bash
sudo bash install.sh global_dev
```

This will:
1. Install ZSH with Oh-My-Zsh globally
2. Install NVM to `/usr/local/nvm`
3. Install latest LTS Node.js
4. Configure NPM global directory
5. Install Yarn globally
6. Create `developers` group
7. Set up proper permissions
8. Add current user to `developers` group

### Step 2: Add Users to Developers Group

**For specific users:**

```bash
sudo bash install.sh add_dev_user john
# or multiple users
sudo bash install.sh add_dev_user john mary bob
```

**For all existing users:**

```bash
sudo bash install.sh add_dev_user --all
```

### Step 3: Force Update (Optional)

To update dotfiles for all existing users:

```bash
sudo bash install.sh global_dev --force
```

This will add all users to `developers` group and copy dotfiles to their home directories.

## User Setup

After being added to the `developers` group, users must:

### Option 1: Logout and Login Again

Simply logout and login again to apply group membership.

### Option 2: Use newgrp Command (Immediate)

```bash
newgrp developers
source /etc/profile.d/nvm.sh
```

## Usage Examples

### For Users in Developers Group

**Install a Node.js version:**

```bash
nvm install 22        # Install Node.js 22
nvm install 20        # Install Node.js 20
nvm use 22           # Use Node.js 22
nvm alias default 22 # Set default to 22
```

**Install npm packages globally:**

```bash
npm install -g typescript
npm install -g @angular/cli
npm install -g vue-cli
```

**Install yarn packages globally:**

```bash
yarn global add create-react-app
yarn global add gatsby-cli
```

**List installed versions:**

```bash
nvm list
npm list -g --depth=0
yarn global list
```

### For New Users

New users automatically get:
- ZSH configured with Oh-My-Zsh
- NVM, NPM, Yarn configured in their shell
- Dotfiles from `/etc/skel/`

But they still need to be added to `developers` group:

```bash
sudo bash install.sh add_dev_user newuser
```

## Directory Structure and Permissions

```
/usr/local/nvm/
├── Owner: root:developers
├── Permissions: 775 (rwxrwxr-x)
├── SGID: Yes (new files inherit group)
│
├── nvm.sh (755)
├── versions/
│   └── node/
│       └── v22.x.x/ (775)
├── npm-global/
│   ├── bin/ (775)
│   └── lib/ (775)
├── yarn-global/ (775)
└── yarn-cache/ (775)

/etc/profile.d/nvm.sh        # Loads for all users (bash/sh)
/etc/zsh/nvm.zsh             # Loads for zsh users
```

## Configuration Files

### System-wide Configuration

1. `/etc/profile.d/nvm.sh` - Loaded by bash/sh users
```bash
export NVM_DIR="/usr/local/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
export NPM_GLOBAL_DIR="/usr/local/nvm/npm-global"
export PATH="$NPM_GLOBAL_DIR/bin:$PATH"
```

2. `/etc/zsh/nvm.zsh` - Loaded by zsh users
```bash
export NVM_DIR="/usr/local/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
export NPM_GLOBAL_DIR="/usr/local/nvm/npm-global"
export PATH="$NPM_GLOBAL_DIR/bin:$PATH"
```

3. `/etc/skel/.zshrc` - Template for new users
4. `/etc/skel/.bashrc` - Template for new users

### User Configuration

Each user's shell config (`.bashrc` or `.zshrc`) includes:

```bash
# NVM configuration
export NVM_DIR="/usr/local/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# NPM global packages directory
export NPM_GLOBAL_DIR="/usr/local/nvm/npm-global"
export PATH="$NPM_GLOBAL_DIR/bin:$PATH"
```

## Troubleshooting

### Permission Denied When Installing Packages

**Problem:** User gets permission denied when running `nvm install` or `npm install -g`

**Solution:**
1. Check if user is in developers group:
   ```bash
   groups $USER
   ```

2. If not, add user to group:
   ```bash
   sudo bash install.sh add_dev_user $USER
   ```

3. Logout and login again, or run:
   ```bash
   newgrp developers
   ```

### NVM Command Not Found

**Problem:** User doesn't have `nvm` command

**Solution:**
1. Source the profile script:
   ```bash
   source /etc/profile.d/nvm.sh
   ```

2. For zsh users:
   ```bash
   source /etc/zsh/nvm.zsh
   ```

3. Add to user's `.bashrc` or `.zshrc` if missing

### NPM/Yarn Packages Not in PATH

**Problem:** Globally installed packages not found

**Solution:**
1. Check if PATH includes npm-global:
   ```bash
   echo $PATH | grep npm-global
   ```

2. If not, reload profile:
   ```bash
   source /etc/profile.d/nvm.sh
   ```

3. Or add to shell config:
   ```bash
   export PATH="/usr/local/nvm/npm-global/bin:$PATH"
   ```

## Security Considerations

### Why Use Group Permissions?

1. **Controlled Access:** Only users in `developers` group can install packages
2. **Shared Resources:** All developers use same Node.js versions
3. **No Sudo Required:** Users don't need sudo for package management
4. **Audit Trail:** Group membership is logged and tracked

### Best Practices

1. **Only add trusted users to developers group**
   - These users can install any npm package globally
   - Packages run with their user permissions

2. **Regular audits**
   ```bash
   # List all users in developers group
   getent group developers
   
   # List globally installed packages
   npm list -g --depth=0
   yarn global list
   ```

3. **Remove users when they leave**
   ```bash
   sudo gpasswd -d username developers
   ```

## Advanced Usage

### Installing Specific Node.js Versions for Projects

```bash
# Install multiple versions
nvm install 18
nvm install 20
nvm install 22

# Use specific version for current session
nvm use 18

# Use .nvmrc file in project
echo "20" > .nvmrc
nvm use  # Automatically uses version from .nvmrc
```

### Managing Multiple Projects

```bash
# Project A uses Node 18
cd /path/to/projectA
nvm use 18
npm install

# Project B uses Node 22
cd /path/to/projectB
nvm use 22
npm install
```

### Yarn vs NPM

Both are available. Choose based on your project:

```bash
# Using NPM
npm install
npm run dev

# Using Yarn
yarn install
yarn dev
```

## Maintenance

### Update NVM

```bash
# Re-run the setup script
sudo bash install.sh global_dev
```

### Update Node.js LTS

```bash
nvm install --lts
nvm alias default 'lts/*'
```

### Clean Up Old Versions

```bash
# List installed versions
nvm list

# Uninstall old version
nvm uninstall 18
```

### Check Disk Usage

```bash
# Check NVM directory size
du -sh /usr/local/nvm

# Check npm cache
du -sh /usr/local/nvm/npm-global

# Check yarn cache
du -sh /usr/local/nvm/yarn-cache

# Clean caches
npm cache clean --force
yarn cache clean
```

## FAQ

**Q: Can users install different Node.js versions?**
A: Yes! All users in developers group can install any Node.js version. They all share the same NVM installation.

**Q: Do changes affect other users?**
A: Installing a Node.js version affects all users (they all share versions). But each user can use different versions with `nvm use`.

**Q: What about package.json dependencies?**
A: Local dependencies (in `node_modules`) are per-project, not affected by this setup.

**Q: Can I still use sudo npm install -g?**
A: You can, but it's not recommended. Use the developers group instead.

**Q: How do I remove a user's access?**
A: Remove them from developers group:
```bash
sudo gpasswd -d username developers
```

**Q: Does this work with Docker?**
A: Yes! The host system tools (NVM, NPM, Yarn) work independently of Docker containers.

## Summary

This setup provides:
- ✅ Shared Node.js versions for all developers
- ✅ No sudo required for package installation
- ✅ Centralized management
- ✅ Proper security through group permissions
- ✅ Easy user management
- ✅ Works for existing and new users
- ✅ Compatible with ZSH and Bash

For issues or questions, refer to the main README.md or check the scripts in `setup/packages/`.

