#!/bin/bash

# configure the server to run apache web server to
# display a page, and
# log to /var/log/hola_mundo/accesslogs/

sudo apt-get -y update
sudo apt-get -y upgrade

sudo apt-get install nginx

sudo systemctl stop nginx

sudo echo '<html><head><title>hello world</title></head><body>hello world.</body></html>' > /var/www/html


cat << EOF > /etc/nginx/nginx.conf

user www-data;
worker_processes  1;

error_log  /var/log/nginx/error.log;
pid        /var/run/nginx.pid;

events {
    worker_connections  1024;
}

http {
    include       /etc/nginx/mime.types;

    access_log  /var/log/hola_mundo/accesslogs/access.log;

    sendfile        on;

    keepalive_timeout  65;
    tcp_nodelay        on;

    gzip  on;
    gzip_disable "MSIE [1-6]\.(?!.*SV1)";

    include /etc/nginx/conf.d/*.conf;
    include /etc/nginx/sites-enabled/*;

   server {

        listen       8900;

    }
}

EOF


sudo systemctl start nginx
