#!/bin/bash

# ======================== Set SSH Timeout ========================
echo 'Checking if SSH timeout already set...'
if grep -q 'ServerAliveInterval 300' /etc/ssh/ssh_config; then
    echo '🔧 SSH timeout already set!'
    exit 0
else
    echo '🔧 Setting up SSH timeout...(12p)'
    echo 'ServerAliveInterval 240' | sudo tee -a /etc/ssh/ssh_config
    echo 'ServerAliveCountMax 3' | sudo tee -a /etc/ssh/ssh_config
    echo '✨ SSH timeout set!'
fi
