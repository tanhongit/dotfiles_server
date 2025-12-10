#!/bin/bash

echo '####################################################################'
echo '############## Change ssh port to your type ################'

# get current ssh port
CURRENT_PORT=$(sudo grep -E "^Port" /etc/ssh/sshd_config | awk '{print $2}')
echo "***** Current ssh port is $CURRENT_PORT *****"

PORT_TYPING=$1

while true; do
    if [[ $ACCEPT_INSTALL =~ ^[Yy]$ ]]; then
        yn="n"
    else
        read -r -p "Do you want to change ssh port? (Y/N)  " yn
    fi

    case $yn in
    [Yy]*)
        echo "=========================== ssh ==========================="

        PORT_REGEX="^[0-9]+$"

        if [[ -n $PORT_TYPING ]] && [[ $PORT_TYPING =~ $PORT_REGEX ]]; then
            new_port=$PORT_TYPING
        else
            read -r -p "Please enter your new ssh port:  " new_port
        fi

        if [[ ! $new_port =~ $PORT_REGEX ]]; then
            echo "Please enter a valid port number"
            continue
        fi

        sudo sed -i "s/#Port [0-9]*/Port $new_port/g" /etc/ssh/sshd_config
        sudo sed -i "s/Port [0-9]*/Port $new_port/g" /etc/ssh/sshd_config

        # Configure firewall to allow new SSH port
        echo ""
        echo "Checking firewall configuration..."

        # Check if ufw is installed and active
        if command -v ufw >/dev/null 2>&1; then
            UFW_STATUS=$(sudo ufw status 2>/dev/null | grep -i "Status:" | awk '{print $2}')
            if [[ "$UFW_STATUS" == "active" ]]; then
                echo "UFW firewall is active. Adding rule for port $new_port..."
                sudo ufw allow "$new_port/tcp" 2>/dev/null
                sudo ufw reload 2>/dev/null
                echo "✓ UFW rule added for port $new_port/tcp"
                echo ""
                echo "Current UFW status:"
                sudo ufw status | grep "$new_port" || echo "Port $new_port not shown yet, but rule was added"
            fi
        fi

        # Check if firewalld is installed and active
        if command -v firewall-cmd >/dev/null 2>&1; then
            FIREWALLD_STATUS=$(sudo systemctl is-active firewalld 2>/dev/null)
            if [[ "$FIREWALLD_STATUS" == "active" ]]; then
                echo "Firewalld is active. Adding rule for port $new_port..."
                sudo firewall-cmd --permanent --add-port="$new_port/tcp" 2>/dev/null
                sudo firewall-cmd --reload 2>/dev/null
                echo "✓ Firewalld rule added for port $new_port/tcp"
                echo ""
                echo "Current firewalld ports:"
                sudo firewall-cmd --list-ports 2>/dev/null
            fi
        fi

        # Disable ssh.socket to allow port in sshd_config to take effect (Ubuntu 22.10+, 24.04, 24.10)
        echo ""
        echo "Disabling ssh.socket to ensure port configuration takes effect..."
        sudo systemctl stop ssh.socket 2>/dev/null || true
        sudo systemctl disable ssh.socket 2>/dev/null || true
        sudo systemctl daemon-reload

        # Restart SSH service
        sudo systemctl restart ssh 2>/dev/null || sudo systemctl restart sshd 2>/dev/null
        sudo systemctl enable ssh 2>/dev/null || sudo systemctl enable sshd 2>/dev/null

        echo ""
        echo "✓ SSH port changed to $new_port"
        echo ""
        echo "Verifying SSH is listening on port $new_port..."
        sudo ss -tlnp | grep ssh || sudo netstat -tlnp | grep ssh
        echo ""
        echo "⚠️  IMPORTANT: Keep this SSH session open!"
        echo "⚠️  Test the new port from another terminal before closing this session:"
        echo "    ssh -p $new_port user@your_server_ip"
        echo ""
        break
        ;;
    [Nn]*) break ;;
    *) echo "Please answer yes or no." ;;
    esac
done
