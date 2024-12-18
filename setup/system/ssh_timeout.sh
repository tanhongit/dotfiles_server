#!/bin/bash

# ======================== Set SSH Timeout ========================
echo 'Checking if SSH timeout already set...'
if grep -q 'ClientAliveInterval 240' /etc/ssh/sshd_config; then
    echo '🔧 SSH timeout already set!'
    exit 0
else
    echo '🔧 Setting up SSH timeout...(4m)'

    echo 'ClientAliveInterval 240' | sudo tee -a /etc/ssh/sshd_config
    echo 'ClientAliveCountMax 3' | sudo tee -a /etc/ssh/sshd_config
    sudo systemctl restart sshd

    echo '✨ SSH timeout set!'
fi
