#!/bin/bash

cd ~ || exit
sudo apt install gcc cmake libpcre3 libpcre3-dev zlib1g zlib1g-dev openssl libssl-dev -y

NGINX_VERSION=$(nginx -v 2>&1 | awk -F '/' '{print $2}' | awk '{print $1}')

wget https://nginx.org/download/nginx-"$NGINX_VERSION".tar.gz
tar zxvf nginx-"$NGINX_VERSION".tar.gz

git clone https://github.com/google/ngx_brotli.git
cd ~/ngx_brotli || exit
git submodule update --init

cd ~/ngx_brotli/deps/brotli || exit

if [ -d "out" ]; then
    rm -rf out
fi
mkdir out && cd out || exit
cmake ..
make
sudo make install

cd ~/nginx-"$NGINX_VERSION" || exit
./configure --with-compat --add-dynamic-module=../ngx_brotli
make modules
sudo cp ./objs/*.so /usr/share/nginx/modules

sudo cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak

if grep -q "load_module modules/ngx_http_brotli_filter_module.so;" /etc/nginx/nginx.conf; then
    echo "module already loaded"
else
    sudo sed -i '1s/^/load_module modules\/ngx_http_brotli_filter_module.so;\nload_module modules\/ngx_http_brotli_static_module.so;\n/' /etc/nginx/nginx.conf
fi

sudo service nginx restart
