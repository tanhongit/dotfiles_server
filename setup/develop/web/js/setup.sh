#!/bin/bash

echo '####################################################################'
echo '################################ Js ################################'
echo '####################################################################'
echo ""

NPM_PACKAGE_LIST=("sass" "yarn")
for packageName in "${NPM_PACKAGE_LIST[@]}"; do
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

echo "=========================== NestJs ==========================="
COMMAND_NAME="nest"
if ! command -v $COMMAND_NAME &>/dev/null; then
    echo "NestJs could not be found. Setting up $COMMAND_NAME."

    while true; do
        if [[ $ACCEPT_INSTALL =~ ^[Yy]$ ]]; then
            yn="y"
        else
            read -r -p "Do you want to install $COMMAND_NAME? (Y/N)  " yn
        fi
        case $yn in
        [Yy]*)
            sudo npm install --global @nestjs/cli
            break
            ;;
        [Nn]*) break ;;
        *) echo "Please answer yes or no." ;;
        esac
    done
else
    echo "$COMMAND_NAME install ok installed"
fi
echo ""
