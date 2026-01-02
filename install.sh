#!/bin/bash

# shellcheck disable=SC1091
set -a
source .env
set +a
set -ue

CURRENT_DIR=$(pwd)

echo '
 ____   ___ _____ _____ ___ _     _____ ____
|  _ \ / _ \_   _|  ___|_ _| |   | ____/ ___|
| | | | | | || | | |_   | || |   |  _| \___ \
| |_| | |_| || | |  _|  | || |___| |___ ___) |
|____/ \___/ |_| |_|   |___|_____|_____|____/

'
echo '⚡ Welcome to tanhongit server setup script! ⚡'
echo '🚀 This script will help you to setup your server 🚀'
echo '🔥 Please run this script with sudo permission 🔥'
echo ''

setup() {
    cd "$CURRENT_DIR" || exit
    bash setup.sh
}

change_ssh_port() {
    cd "$CURRENT_DIR/setup/system" || exit
    bash change-port.sh
}

ssh_timeout() {
    cd "$CURRENT_DIR/setup/system" || exit
    bash ssh_timeout.sh
}

php() {
    cd "$CURRENT_DIR/setup/develop/web/php" || exit
    bash php-handler.sh
}

php_extension() {
    cd "$CURRENT_DIR/setup/develop/web/php" || exit
    bash php-extension.sh "$1"
}

lazydocker() {
    cd "$CURRENT_DIR/setup/develop" || exit
    bash lazydocker.sh
}

global_dev_setup() {
    cd "$CURRENT_DIR/setup/packages" || exit
    if [ "${2:-}" = "-f" ] || [ "${2:-}" = "--force" ]; then
        bash global-dev-setup.sh --force
    else
        bash global-dev-setup.sh
    fi
}

zabbix_server() {
    cd "$CURRENT_DIR/setup/system" || exit
    sudo bash zabbix.sh server
}

zabbix_client() {
    local server_ip="${1:-}"
    cd "$CURRENT_DIR/setup/system" || exit
    if [ -n "$server_ip" ]; then
        sudo bash zabbix.sh client "$server_ip"
    else
        sudo bash zabbix.sh client
    fi
}

fix_mysql_frozen() {
    cd "$CURRENT_DIR/setup/system" || exit
    sudo bash fix-mysql-frozen.sh
}

usage() {
    echo "Usage: bash $0 [command] [args]"
    echo ''
    echo 'Commands:'
    echo '  setup           Show welcome message'
    echo '  ssh_port        Change ssh port'
    echo '  ssh_timeout     Configure SSH timeout (auto disconnect after 5min idle)'
    echo '  php             Install php'
    echo '  php_extension   Install php extension'
    echo '  lazydocker      Install lazydocker'
    echo '  global_dev      Setup NVM, NPM, Yarn, ZSH globally for all users'
    echo '  zabbix_server   Install Zabbix Server (auto-detect Nginx/Apache)'
    echo '  zabbix_client   Install Zabbix Agent (client) [server_ip]'
    echo ''
    echo 'Args for global_dev:'
    echo '  -f, --force     Force copy/update dotfiles to all existing users'
    echo ''
    echo 'Args for ssh_port:'
    echo '  [port]          New ssh port (valid port number)'
    echo ''
    echo 'Args for php_extension:'
    echo '  [version]       PHP version (valid version number)'
    echo ''
    echo 'Args for zabbix_client:'
    echo '  [server_ip]     Zabbix Server IP (optional, will prompt if not provided)'
    echo ''
    echo 'Example:'
    echo "  bash $0 setup"
    echo "  bash $0 ssh_port 12345"
    echo "  bash $0 ssh_timeout"
    echo "  bash $0 php"
    echo "  bash $0 php_extension 8.4"
    echo "  bash $0 lazydocker"
    echo "  bash $0 global_dev"
    echo "  bash $0 global_dev -f"
    echo "  bash $0 zabbix_server"
    echo "  bash $0 zabbix_client"
    echo "  bash $0 zabbix_client 192.168.1.100"
    echo "  bash $0 fix_mysql"
    echo ''
}

case "${1:-}" in
    setup | s | a)
        setup
        ;;

    ssh_port | sp)
        change_ssh_port
        ;;

    ssh_timeout | st)
        ssh_timeout
        ;;

    php | php-install)
        php
        ;;

    php_extension | pe)
        php_extension "${2:-}"
        ;;

    lazydocker | ld)
        lazydocker
        ;;

    global_dev | gd)
        global_dev_setup "$@"
        ;;

    zabbix_server | zs)
        zabbix_server
        ;;

    zabbix_client | zc)
        zabbix_client "${2:-}"
        ;;

    fix_mysql | fix_mysql_frozen | fmf)
        fix_mysql_frozen
        ;;

    *)
        usage
        exit 1
        ;;
esac

