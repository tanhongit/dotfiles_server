#!/bin/bash

REQUIRED_PKG="git"
PKG_OK=$(dpkg-query -W --showformat='${Status}\n' $REQUIRED_PKG | grep "install ok installed")
echo "Checking for $REQUIRED_PKG: $PKG_OK"
if [ "" = "$PKG_OK" ]; then
    echo "No $REQUIRED_PKG. Setting up $REQUIRED_PKG."
    sudo apt-get install -y $REQUIRED_PKG
fi

echo "=========================== zsh ==========================="
bash zsh.sh

installPackages() {
    PACKAGE_LIST=("curl" "wget" "vim" "tmux" "nano" "npm" "certbot" "python3-certbot-nginx" "fail2ban" "htop")

    for packageName in "${PACKAGE_LIST[@]}"; do
        echo "=========================== $packageName ==========================="

        PKG_OK=$(dpkg-query -W --showformat='${Status}\n' "$packageName" | grep "install ok installed")
        echo "Checking for $packageName: $PKG_OK"
        if [ "" = "$PKG_OK" ]; then
            echo "No $packageName. Setting up $packageName."
            sudo apt-get install -y "$packageName"
        fi
        echo ""
    done
}
installPackages

echo "=========================== nvm ==========================="
bash nvm.sh
echo ""

echo "====================== redis-server ======================="
bash redis.sh
echo ""
