#!/bin/bash

COMMAND_NAME="php"
if ! command -v $COMMAND_NAME &>/dev/null; then
    echo "=========================== php ==========================="
    sudo apt update
    sudo apt install lsb-release gnupg2 ca-certificates apt-transport-https software-properties-common -y
    sudo add-apt-repository ppa:ondrej/php
    sudo apt update

    echo "*****************"
    echo 'Auto checking for latest version...'
    bash php-handler.sh
else
    echo "$COMMAND_NAME install ok installed"
fi
