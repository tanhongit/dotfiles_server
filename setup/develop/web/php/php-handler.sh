#!/bin/bash

PHP_VERSION=$(curl -s https://www.php.net/downloads | grep -oP 'PHP [0-9]+\.[0-9]+' | head -1 | awk '{print $2}')

phpExtensions() {
    sudo apt install php"$PHP_VERSION" php"$PHP_VERSION"-{bcmath,common,fpm,xml,mysql,zip,intl,ldap,gd,bz2,curl,mbstring,pgsql,opcache,soap,redis,imagick} -y
    sudo systemctl enable php"$PHP_VERSION"-fpm
    sudo systemctl start php"$PHP_VERSION"-fpm
}

phpExtensions
