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

    # Restart SSH service with check for service name
    if systemctl list-units --full -all | grep -Fq "sshd.service"; then
        sudo systemctl restart sshd
    elif systemctl list-units --full -all | grep -Fq "ssh.service"; then
        sudo systemctl restart ssh
    else
        echo "⚠️ Could not find SSH service, please restart it manually"
    fi

    echo '✨ SSH timeout set!'
fi
