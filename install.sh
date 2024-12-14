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

php() {
    cd "$CURRENT_DIR/setup/develop/web/php" || exit
    bash php-handler.sh
}

php_extension() {
    cd "$CURRENT_DIR/setup/develop/web/php" || exit
    bash php-extension.sh "$1"
}

usage() {
    echo "Usage: bash $0 [command] [args]"
    echo ''
    echo 'Commands:'
    echo '  setup           Show welcome message'
    echo '  ssh_port        Change ssh port'
    echo '  php             Install php'
    echo '  php_extension   Install php extension'
    echo ''
    echo 'Args for ssh_port:'
    echo '  [port]          New ssh port (valid port number)'
    echo ''
    echo 'Args for php_extension:'
    echo '  [version]       PHP version (valid version number)'
    echo ''
    echo 'Example:'
    echo "  bash $0 setup"
    echo "  bash $0 ssh_port 12345"
    echo "  bash $0 php"
    echo "  bash $0 php_extension 8.3"
    echo ''
}

case "$1" in
    setup | "")
        setup
        ;;

    ssh_port | sp)
        change_ssh_port
        ;;

    php | php-install)
        php
        ;;

    php_extension | pe)
        php_extension "$2"
        ;;

    *)
        usage
        exit 1
        ;;
esac
