#!/bin/bash

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

usage() {
    echo "Usage: bash $0 [command] [args]"
    echo ''
    echo 'Commands:'
    echo '  setup           Show welcome message'
    echo '  ssh_port        Change ssh port'
    echo ''
    echo 'Args for ssh_port:'
    echo '  [port]          New ssh port (valid port number)'
    echo ''
    echo 'Example:'
    echo "  bash $0 setup"
    echo "  bash $0 ssh_port 12345"
    echo ''
}

case "$1" in
    setup)
        setup
        ;;

    ssh_port)
        change_ssh_port
        ;;
    *)
        usage
        exit 1
        ;;
esac
