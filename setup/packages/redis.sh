#!/bin/bash

COMMAND_NAME="redis-server"
if ! command -v $COMMAND_NAME &>/dev/null; then
    echo "$COMMAND_NAME could not be found. Setting up $COMMAND_NAME."

    sudo apt install redis-server -y
    sudo systemctl enable redis-server.service

    sudo sed -i 's/supervised no/supervised systemd/g' /etc/redis/redis.conf

    # generate password: openssl rand 60 | openssl base64 -A
    # Please change the password below
    sudo sed -i 's/# requirepass foobared/requirepass ZQ9jwNHuXVHYVqAC6dLNTCILcnL9oU6+BooVxWOeEPPuu0BYKybrMGHbfHWWpyixNl+6mSm35Row/g' /etc/redis/redis.conf

    #sudo sed -i 's/# maxmemory <bytes>/maxmemory 256mb/g' /etc/redis/redis.conf
    #sudo sed -i 's/# maxmemory-policy noeviction/maxmemory-policy allkeys-lru/g' /etc/redis/redis.conf

    sudo systemctl restart redis-server.service
else
    echo "$COMMAND_NAME install ok installed"
fi
echo ""
