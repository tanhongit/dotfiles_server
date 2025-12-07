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

echo "####################################################################"
echo "######################## install lazydocker ########################"
while true; do
    if [[ $ACCEPT_INSTALL =~ ^[Yy]$ ]]; then
        yn="y"
    else
        read -r -p "Do you want to install lazydocker? (Y/N)  " yn
    fi
    case $yn in
    [Yy]*)
        cd "$THIS_DIR"/setup/develop/ || exit
        bash lazydocker.sh
        cd "$THIS_DIR" || exit
        break
        ;;
    [Nn]*) break ;;
    *) echo "Please answer yes or no." ;;
    esac
done
