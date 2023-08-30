#!/bin/bash

COMMAND_NAME="php"
if ! command -v $COMMAND_NAME &>/dev/null; then
    echo "=========================== php ==========================="
    sudo apt install lsb-release gnupg2 ca-certificates apt-transport-https software-properties-common -y
    sudo add-apt-repository ppa:ondrej/php

    echo "*****************"
    echo 'Auto checking for latest version...'
    PHP_VERSION=$(curl -s https://www.php.net/downloads | grep -oP 'PHP [0-9]+\.[0-9]+' | head -1 | awk '{print $2}')

    phpExtensions() {
        sudo apt install php"$PHP_VERSION" php"$PHP_VERSION"-{bcmath,common,fpm,xml,mysql,zip,intl,ldap,gd,bz2,curl,mbstring,pgsql,opcache,soap,redis} -y
        sudo systemctl enable php"$PHP_VERSION"-fpm
        sudo systemctl start php"$PHP_VERSION"-fpm
    }

    phpExtensions
else
    echo "$COMMAND_NAME install ok installed"
fi
