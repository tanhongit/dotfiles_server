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

        # Disable ssh.socket to allow port in sshd_config to take effect (Ubuntu 22.10+, 24.04, 24.10)
        echo "Disabling ssh.socket to ensure port configuration takes effect..."
        sudo systemctl stop ssh.socket 2>/dev/null || true
        sudo systemctl disable ssh.socket 2>/dev/null || true
        sudo systemctl daemon-reload

        # Restart SSH service
        sudo systemctl restart ssh 2>/dev/null || sudo systemctl restart sshd 2>/dev/null
        sudo systemctl enable ssh 2>/dev/null || sudo systemctl enable sshd 2>/dev/null

        echo ""
        echo "SSH port changed to $new_port"
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
