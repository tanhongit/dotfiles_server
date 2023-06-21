#!/bin/bash

echo "======================= Clear ========================"

cd ../others || exit
bash clear.sh
cd ../options || exit

echo "=========================== copy overwrite ==========================="
while true; do
    if [[ $ACCEPT_INSTALL =~ ^[Yy]$ ]]; then
        yn="y"
    else
        echo "Do you want copy and overwrite existing config folders from this source to your os?"
        echo "If you have just installed ubuntu on your machine, you can copy the config by selecting Y/Yes."
        echo "Please select N/No to skip if your os was installed long ago to avoid conflicts."
        read -r -p "Please choose (Y/N)  " yn
    fi

    case $yn in
    [Yy]*)
        sudo apt install gir1.2-gda-5.0 gir1.2-gsound-1.0 -y # install gsound for 'Pano Clipboard Manager'
        cp -TRv ../../home "${ZSH_CUSTOM:-$HOME/}"
        break
        ;;
    [Nn]*) break ;;
    *) echo "Please answer yes or no." ;;
    esac
done
