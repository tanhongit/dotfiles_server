#!/bin/bash

if [ -x "$(command -v nginx)" ]; then
    echo "Nginx already installed"
elif [ -x "$(command -v apache2)" ]; then
    echo "Apache2 already installed"
else
    echo "=========================== nginx ==========================="
    PKG_OK=$(dpkg-query -W --showformat='${Status}\n' nginx | grep "install ok installed")
    echo "Checking for nginx: $PKG_OK"
    if [ "" = "$PKG_OK" ]; then
        echo "No nginx. Setting up nginx."
        sudo apt install -y nginx
        systemctl enable nginx
        sudo ufw allow in "Nginx Full"
        systemctl reload nginx
        sudo apt install perl nginx -y
    fi
fi
echo ''
