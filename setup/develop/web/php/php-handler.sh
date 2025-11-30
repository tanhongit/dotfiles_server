#!/bin/bash

PHP_VERSION=$(curl -s https://www.php.net/downloads | grep -oP 'PHP [0-9]+\.[0-9]+' | head -1 | awk '{print $2}')

setPHPVersion() {
    PHP_VERSION=$1
    echo "You choose php$PHP_VERSION"
}
PS3="Press * to setup default version - php$PHP_VERSION (latest version is php$PHP_VERSION) \n Select setup the php version (Warning: choose new version may not be successful because it is not yet complete support, please choose the stable version): "
select opt in "8.5" "8.4" "8.3" "8.2" "8.1" "8.0" "7.4" "7.2" "7.0" "5.6"; do
    case $opt in
    "8.5")
        setPHPVersion "8.5"
        break
        ;;
    "8.4")
        setPHPVersion "8.4"
        break
        ;;
    "8.3")
        setPHPVersion "8.3"
        break
        ;;
    "8.2")
        setPHPVersion "8.2"
        break
        ;;
    "8.1")
        setPHPVersion "8.1"
        break
        ;;
    "8.0")
        setPHPVersion "8.0"
        break
        ;;
    "7.4")
        setPHPVersion "7.4"
        break
        ;;
    "7.2")
        setPHPVersion "7.2"
        break
        ;;
    "7.0")
        setPHPVersion "7.0"
        break
        ;;
    "5.6")
        setPHPVersion "5.6"
        break
        ;;
    *)
        echo "Invalid option $REPLY"
        echo "Auto set default: php$PHP_VERSION"
        break
        ;;
    esac
done

phpExtensions() {
    sudo apt install php"$PHP_VERSION"
    bash php-extension.sh "$PHP_VERSION"
    sudo systemctl enable php"$PHP_VERSION"-fpm
    sudo systemctl start php"$PHP_VERSION"-fpm
}

phpExtensions
