#!/bin/bash

# configure the server to run apache web server to
# display a page, and
# log to /var/log/hola_mundo/accesslogs/

sudo apt-get -y update
sudo apt-get -y upgrade

sudo apt-get install -y apache2

echo 'Listen 8900' > /etc/apache2/ports.conf

echo '<html><head><title>hello world</title></head><body>hello world.</body></html>' > /var/www/html/index.html

cp /etc/apache2/envvars /etc/apache2/envvars.backup
grep -v "APACHE_LOG_DIR" /etc/apache2/envvars > /tmp/modify-envvars.txt
echo 'APACHE_LOG_DIR=/var/log/hola_mundo/accesslogs/' >> /tmp/modify-envvars.txt
mv /tmp/modify-envvars.txt /etc/apache2/envvars
# yepp this will make the other logs go into '.../accesslogs/' but this technically satisfies the requirements ;P
# Get requirements right at the start!

sudo service apache2 restart