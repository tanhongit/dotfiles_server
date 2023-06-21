#!/bin/bash

COMMAND_NAME="nvm"
if ! command -v $COMMAND_NAME &>/dev/null; then
    echo "$COMMAND_NAME could not be found. Setting up $COMMAND_NAME."
    curl https://raw.githubusercontent.com/nvm-sh/nvm/master/install.sh | bash
    # shellcheck disable=SC1090
    source ~/.bashrc

    nvm install node
    nvm use node
    nvm alias default node
else
    echo "$COMMAND_NAME install ok installed"
fi
echo ""
