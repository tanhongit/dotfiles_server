#!/bin/bash

cd ~ || exit
sudo apt install gcc cmake libpcre3 libpcre3-dev zlib1g zlib1g-dev openssl libssl-dev

wget https://nginx.org/download/nginx-1.18.0.tar.gz
tar zxvf nginx-1.18.0.tar.gz

git clone https://github.com/google/ngx_brotli.git
cd ~/ngx_brotli || exit
git submodule update --init

cd ~/nginx-1.18.0 || exit
./configure --with-compat --add-dynamic-module=../ngx_brotli
make modules
sudo cp ./objs/*.so /usr/share/nginx/modules

cp /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak

sudo sed -i '1s/^/load_module modules\/ngx_http_brotli_filter_module.so;\nload_module modules\/ngx_http_brotli_static_module.so;\n/' /etc/nginx/nginx.conf

sudo service nginx restart
