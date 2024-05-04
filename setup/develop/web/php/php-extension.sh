#!/bin/bash

PHP_VERSION=$1

if [ -z "$PHP_VERSION" ]; then
    PHP_VERSION=$(php -v | grep -oP 'PHP [0-9]+\.[0-9]+' | head -1 | awk '{print $2}')
fi

sudo apt install php"$PHP_VERSION"-{bcmath,common,fpm,xml,mysql,zip,intl,ldap,gd,bz2,curl,mbstring,pgsql,opcache,soap,redis,imagick} -y
