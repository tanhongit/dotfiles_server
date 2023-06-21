#!/bin/bash

echo '####################################################################'
echo '####################################################################'
echo '######################### For Ubuntu Server ########################'
echo '####################################################################'
echo '####################################################################'
echo ''
echo "=========================== update ==========================="
sudo apt-get -y update
sudo apt-get -y upgrade

echo '####################################################################'
echo '######################### Run package list #########################'
echo '####################################################################'
echo ''

cd setup/packages || exit
bash list.sh
cd ../../

echo '####################################################################'
while true; do
    if [[ $ACCEPT_INSTALL =~ ^[Yy]$ ]]; then
        yn="y"
    else
        read -r -p "Do you want to install some packages, programs for Developer? (Y/N)  " yn
    fi
    case $yn in
    [Yy]*)
        cd setup/develop || exit
        bash setup.sh
        cd ../../
        break
        ;;
    [Nn]*) break ;;
    *) echo "Please answer yes or no." ;;
    esac
done
