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

| Command               | Description                                             |
|-----------------------|---------------------------------------------------------|
| `setup`, `s`, `a`     | Setup the server                                        |
| `ssh_port`, `sp`      | Change the SSH port                                     |
| `ssh_timeout`, `st`   | Configure SSH timeout (auto disconnect after 5min idle) |
| `php`, `php-install`  | Install PHP version you want                            |
| `php_extension`, `pe` | Install PHP extensions                                  |
| `lazydocker`, `ld`    | Install lazydocker                                      |
| `global_dev`, `gd`    | Setup NVM, NPM, Yarn, ZSH globally for all users        |
| `zabbix_server`, `zs` | Install Zabbix Server with auto web server detection    |
| `zabbix_client`, `zc` | Install Zabbix Agent (client)                           |
| `fix_mysql`, `fmf`    | Fix MySQL FROZEN issue (when downgrading from MariaDB)  |

### Global Dev Setup

Setup development environment globally for all users (including new users):

```bash
sudo bash install.sh global_dev
# or
sudo bash install.sh gd
```

This will install and configure:
- ✓ ZSH with Oh-My-Zsh (Powerlevel10k theme)
- ✓ NVM (Node Version Manager)
- ✓ Node.js (LTS version)
- ✓ NPM (Node Package Manager)
- ✓ Yarn (Package Manager)

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

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
