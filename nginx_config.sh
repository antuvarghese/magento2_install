#!/bin/bash
echo "enter domain"
read domain
echo "enter magento user name"
read magentouser
echo "enter php-fpm-socket"
read phpsocket
if [ -f "/etc/nginx/sites-available/$domain" ]
then
   cp /etc/nginx/sites-available/$domain /etc/nginx/sites-available/$domain-back.old
fi
echo "upstream fastcgi_backend {
        server  unix:/run/php/phpsocket;
}

server {
    if (\$host = domain) {
        return 301 https://\$host\$request_uri;
    } # managed by Certbot


    listen 80;
    listen [::]:80;
    server_name domain www.domain;
    return 301 https://\$server_name\$request_uri;
    root /home/magentouser/domain/public;

    access_log off;
    error_log  /var/log/nginx/domain-error.log error;

}

server {

        listen 443 ssl http2;
        server_name domain www.domain;
        ssl_certificate /etc/letsencrypt/live/domain/fullchain.pem; # managed by Certbot
        ssl_certificate_key /etc/letsencrypt/live/domain/privkey.pem; # managed by Certbot

        set \$MAGE_ROOT /home/magentouser/domain/public;
        set \$MAGE_MODE developer;
        include /home/magentouser/domain/public/nginx.conf.sample;
        include fastcgi.conf;


}" > /etc/nginx/sites-available/$domain

sed -ie 's/magentouser/'$magentouser'/g' /etc/nginx/sites-available/$domain
sed -ie 's/domain/'$domain'/g' /etc/nginx/sites-available/$domain
sed -ie 's/phpsocket/'$phpsocket'/g' /etc/nginx/sites-available/$domain

ln -s /etc/nginx/sites-available/$domain /etc/nginx/sites-enabled/
nginx -s reload
