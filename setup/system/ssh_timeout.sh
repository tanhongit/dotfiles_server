#!/bin/bash

# ======================== Set SSH Timeout ========================
# SSH sẽ tự động ngắt kết nối sau 5 phút không có hoạt động
# ClientAliveInterval 60 = gửi keepalive mỗi 60 giây
# ClientAliveCountMax 5 = sau 5 lần không phản hồi (5 x 60s = 300s = 5 phút) thì ngắt

echo 'Checking if SSH timeout already set...'

# Remove old configurations if exist
sudo sed -i '/^ClientAliveInterval/d' /etc/ssh/sshd_config 2>/dev/null
sudo sed -i '/^ClientAliveCountMax/d' /etc/ssh/sshd_config 2>/dev/null

echo '🔧 Setting up SSH timeout...(5 minutes idle timeout)'
echo ''

# Add new configuration
echo 'ClientAliveInterval 60' | sudo tee -a /etc/ssh/sshd_config
echo 'ClientAliveCountMax 5' | sudo tee -a /etc/ssh/sshd_config

# Disable SSH socket to ensure sshd_config port takes effect (Ubuntu 22.10+)
echo ''
echo 'Disabling ssh.socket to ensure configuration takes effect...'
if systemctl list-units --full -all | grep -Fq "ssh.socket"; then
    sudo systemctl stop ssh.socket
    sudo systemctl disable ssh.socket
    sudo systemctl daemon-reload
    echo '✓ ssh.socket disabled'
fi

# Restart SSH service with check for service name
echo 'Restarting SSH service...'
if systemctl list-units --full -all | grep -Fq "sshd.service"; then
    sudo systemctl restart sshd
    sudo systemctl enable sshd
    echo '✓ sshd.service restarted'
elif systemctl list-units --full -all | grep -Fq "ssh.service"; then
    sudo systemctl restart ssh
    sudo systemctl enable ssh
    echo '✓ ssh.service restarted'
else
    printf "⚠️ Could not find SSH service, please restart it manually\n"
fi

echo ''
echo '✨ SSH timeout set! Sessions will disconnect after 5 minutes of inactivity.'
echo '📌 Configuration: 60s interval × 5 retries = 300s (5 minutes)'
echo '📌 Note: Keep your current session open and test with a new connection.'
echo ''
echo '🔍 Verify configuration:'
echo '   grep -E "ClientAlive" /etc/ssh/sshd_config'
