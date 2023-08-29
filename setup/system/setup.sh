#!/bin/bash

NPM_SYSTEM_LIST=("pm2")
for packageName in "${NPM_SYSTEM_LIST[@]}"; do
    echo "=========================== $packageName ==========================="
    if ! command -v "$packageName" &>/dev/null; then
        echo "$packageName could not be found. Setting up $packageName."
        while true; do
            if [[ $ACCEPT_INSTALL =~ ^[Yy]$ ]]; then
                yn="y"
            else
                read -r -p "Do you want to install $packageName? (Y/N)  " yn
            fi
            case $yn in
            [Yy]*)
                sudo npm install -g "$packageName"
                break
                ;;
            [Nn]*) break ;;
            *) echo "Please answer yes or no." ;;
            esac
        done
    else
        echo "$packageName install ok installed"
    fi
    echo ""
done
