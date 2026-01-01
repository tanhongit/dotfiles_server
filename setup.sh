#!/bin/bash

THIS_DIR=$(pwd)

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

cd "$THIS_DIR"/setup/packages || exit
bash list.sh
cd "$THIS_DIR" || exit

echo '####################################################################'
while true; do
    if [[ $ACCEPT_INSTALL =~ ^[Yy]$ ]]; then
        yn="y"
    else
        read -r -p "Do you want to install some packages, programs for Developer? (Y/N)  " yn
    fi
    case $yn in
    [Yy]*)
        cd "$THIS_DIR"/setup/develop || exit
        bash setup.sh
        cd "$THIS_DIR" || exit
        break
        ;;
    [Nn]*) break ;;
    *) echo "Please answer yes or no." ;;
    esac
done

echo '####################################################################'
echo '############################# System ###############################'
echo '####################################################################'
echo ''
cd "$THIS_DIR"/setup/system || exit
bash setup.sh
bash change-port.sh

echo ''
echo '####################################################################'
echo '########################### after setup ############################'
echo '####################################################################'
echo ''
cd "$THIS_DIR"/setup/options || exit
bash after-setup.sh

echo "####################################################################"
echo "######################### install docker ###########################"
while true; do
    if [[ $ACCEPT_INSTALL =~ ^[Yy]$ ]]; then
        yn="y"
    else
        read -r -p "Do you want to install docker? (Y/N)  " yn
    fi
    case $yn in
    [Yy]*)
        cd "$THIS_DIR"/setup/develop/ || exit
        bash docker.sh
        cd "$THIS_DIR" || exit
        break
        ;;
    [Nn]*) break ;;
    *) echo "Please answer yes or no." ;;
    esac
done

echo ''
echo "####################################################################"
echo "####################### install Zabbix #############################"
echo "####################################################################"
echo ''
while true; do
    read -r -p "Do you want to install Zabbix? (server/client/no)  " zabbix_choice
    case $zabbix_choice in
    [Ss][Ee][Rr][Vv][Ee][Rr]|server)
        cd "$THIS_DIR"/setup/system/ || exit
        sudo bash zabbix.sh server
        cd "$THIS_DIR" || exit
        break
        ;;
    [Cc][Ll][Ii][Ee][Nn][Tt]|client)
        cd "$THIS_DIR"/setup/system/ || exit
        sudo bash zabbix.sh client
        cd "$THIS_DIR" || exit
        break
        ;;
    [Nn][Oo]|no|n) break ;;
    *) echo "Please answer server, client, or no." ;;
    esac
done

