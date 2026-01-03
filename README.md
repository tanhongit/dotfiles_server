# Dotfiles Server

This script is used to set up a new server with my dotfiles.

## OS Availability:
- [x] Ubuntu 20.04
- [x] Ubuntu 22.04
- [x] Debian 10

## Installation

Clone the repository and run the script:

```bash
# git clone --depth=1 https://github.com/tanhongit/dotfiles_server.git
git clone git@github.com:tanhongit/dotfiles_server.git
```

```bash
cd dotfiles_server
```

```bash
./install.sh a
```

> Note: You may need to make the script executable by running `chmod +x install.sh` before running it.
> 
> ```bash
> chmod +x install.sh
> ```

## Usage

The runner has the following commands:

| Command                   | Description                                             |
|---------------------------|---------------------------------------------------------|
| `setup`, `s`, `a`         | Setup the server                                        |
| `ssh_port`, `sp`          | Change the SSH port                                     |
| `ssh_timeout`, `st`       | Configure SSH timeout (auto disconnect after 5min idle) |
| `php`, `php-install`      | Install PHP version you want                            |
| `php_extension`, `pe`     | Install PHP extensions                                  |
| `lazydocker`, `ld`        | Install lazydocker                                      |
| `global_dev`, `gd`        | Setup NVM, NPM, Yarn, ZSH globally for all users        |
| `add_dev_user`, `adu`     | Add user(s) to developers group for dev tools access    |
| `zabbix_server`, `zs`     | Install Zabbix Server with auto web server detection    |
| `zabbix_client`, `zc`     | Install Zabbix Agent (client)                           |
| `update_zabbix_ip`, `uzi` | Update Zabbix Server IP for installed agent             |
| `fix_mysql`, `fmf`        | Fix MySQL FROZEN issue (when downgrading from MariaDB)  |

### Global Dev Setup

Setup development environment globally for all users (including new users):

```bash
sudo bash install.sh global_dev
# or
sudo bash install.sh gd
```

This will install and configure:
- ✓ ZSH with Oh-My-Zsh (Powerlevel10k theme)
- ✓ NVM (Node Version Manager) at `/usr/local/nvm`
- ✓ Node.js (LTS version)
- ✓ NPM (Node Package Manager) with global packages at `/usr/local/nvm/npm-global`
- ✓ Yarn (Package Manager) with global packages at `/usr/local/nvm/yarn-global`
- ✓ Creates `developers` group with proper permissions

**Force update dotfiles for all existing users:**

```bash
sudo bash install.sh global_dev -f
# or
sudo bash install.sh gd --force
```

The `-f` or `--force` flag will:
- Force copy/update all dotfiles (.zshrc, .zsh_aliases, .p10k.zsh) from `home/` folder to all existing users
- Backup existing dotfiles before updating
- Apply new configuration to all users with UID >= 1000
- Automatically add all existing users to `developers` group

#### Managing User Permissions

After installing global dev tools, users need to be added to the `developers` group to use NVM, NPM, and Yarn:

**Add specific user(s):**

```bash
sudo bash install.sh add_dev_user john
# or multiple users
sudo bash install.sh add_dev_user john mary bob
```

**Add all existing users:**

```bash
sudo bash install.sh add_dev_user --all
# or
sudo bash install.sh adu -a
```

**Important:** Users must logout and login again (or run `newgrp developers`) to apply group membership.

After that, users can:
- Install Node.js versions: `nvm install 22`
- Install npm packages globally: `npm install -g <package>`
- Install yarn packages globally: `yarn global add <package>`

**Benefits of using `developers` group:**
- ✓ No need to use `sudo` for installing packages
- ✓ All users in the group share the same Node.js versions
- ✓ Centralized package management
- ✓ Secure permissions (only authorized users can install packages)

### Zabbix Setup

Setup Zabbix monitoring system with automatic web server detection:

**Install Zabbix Server:**

```bash
sudo bash install.sh zabbix_server
# or
sudo bash install.sh zs
```

Features:
- ✓ Auto-detects Nginx or Apache (or lets you choose)
- ✓ Installs MySQL database
- ✓ Configures Zabbix Server, Frontend, and Agent
- ✓ Generates secure random passwords
- ✓ Configures firewall automatically
- ✓ Supports Ubuntu 20.04, 22.04, 24.04
- ✓ Zabbix 7.0 LTS

**Install Zabbix Agent (Client):**

```bash
# Method 1: Will prompt for Server IP
sudo bash install.sh zabbix_client
# or
sudo bash install.sh zc

# Method 2: Pass Server IP directly
sudo bash install.sh zabbix_client 192.168.1.100
# or
sudo bash install.sh zc 192.168.1.100
```

Features:
- ✓ Installs Zabbix Agent
- ✓ Prompts for Zabbix Server IP
- ✓ Configures agent to connect to server
- ✓ Configures firewall automatically

**Update Zabbix Server IP (for already installed agents):**

```bash
# Method 1: Will prompt for new Server IP
sudo bash install.sh update_zabbix_ip
# or
sudo bash install.sh uzi

# Method 2: Pass new Server IP directly
sudo bash install.sh update_zabbix_ip 192.168.1.200
# or
sudo bash install.sh uzi 192.168.1.200
```

Features:
- ✓ Updates existing Zabbix Agent configuration
- ✓ Validates IP address format
- ✓ Creates backup before changes
- ✓ Auto-restarts agent service
- ✓ Verifies connection to new server
- ✓ Supports both Zabbix Agent and Agent2

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
