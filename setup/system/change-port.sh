#!/bin/bash

echo '####################################################################'
echo '############## Change ssh port to your type ################'

# get current ssh port
CURRENT_PORT=$(sudo grep -E "^Port" /etc/ssh/sshd_config | awk '{print $2}')
echo "***** Current ssh port is $CURRENT_PORT *****"

while true; do
    if [[ $ACCEPT_INSTALL =~ ^[Yy]$ ]]; then
        yn="n"
    else
        read -r -p "Do you want to change ssh port? (Y/N)  " yn
    fi

    case $yn in
    [Yy]*)
        echo "=========================== ssh ==========================="
        read -r -p "Please enter your new ssh port:  " new_port
        sudo sed -i "s/#Port [0-9]*/Port $new_port/g" /etc/ssh/sshd_config
        sudo sed -i "s/Port [0-9]*/Port $new_port/g" /etc/ssh/sshd_config
        sudo systemctl restart sshd
        echo "SSH port changed to $new_port"
        break
        ;;
    [Nn]*) break ;;
    *) echo "Please answer yes or no." ;;
    esac
done
