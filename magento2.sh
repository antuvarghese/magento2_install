#!/bin/bash
if apt list --installed elasticsearch | grep -q 'elasticsearch'
then
    echo -e "\e[1;31m elasticsearch is already installed. \e[0m"
    echo " Skipping elasticsearch installation..."
else
    echo " elasticsearch installing... "
    curl -fsSL https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
    if [ ! -f "/etc/apt/sources.list.d/elastic-7.x.list" ]
    then
       echo "deb https://artifacts.elastic.co/packages/7.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elastic-7.x.list
    fi
    apt update
    apt install elasticsearch
    systemctl start elasticsearch
    systemctl enable elasticsearch
    echo " elasticsearch is successfully installed "
fi
echo " Testing elasticsearch... "
sleep 5
curl -X GET 'http://localhost:9200'
curl -XGET 'http://localhost:9200/_nodes?pretty'
echo " composer is installing... "
apt install composer -y
echo -e "\n"
yes | composer --version
echo -e "\n"
echo " composer is installed "
echo -e "\e[0;36m Enter username \e[0m"
read username
echo -e "\e[0;36m Enter domain \e[0m"
read domain
cd /home/$username/$domain/
if [ -d "/home/$username/$domain/public" ]
then
   mv public public.old
fi
wget -q https://github.com/magento/magento2/archive/2.4.3.tar.gz
tar -zxvf 2.4.3.tar.gz
mv magento2-*/ public/
cd public
yes | composer install
chown -R $username:ploi /home/$username/$domain/public

echo -e "\e[1;34m --> Enter base-url [https://domain.com]\e[0m"
read url
echo -e "\e[1;32m --> Enter Magento2 Database Name \e[0m"
read dbname
echo -e "\e[1;32m --> Enter Magento2 Database User \e[0m"
read dbuser
echo -e "\e[1;32m --> Enter Magento2 Database password \e[0m"
read dbpass
echo -e "\e[1;36m setup magento2 admin \e[0m"
#admin name generator
adminname=admin_$(cat /dev/urandom | tr -dc '[:alpha:]' | fold -w ${1:-3} | head -n 1)
#admin pass generator
adminpass=#$(openssl rand -base64 10)8

echo -e "\e[1;31m + Enter admin email \e[0m"
read adminmail
php bin/magento setup:install --base-url=$url --db-host=127.0.0.1 --db-name=$dbname --db-user=$dbuser --db-password=$dbpass --admin-firstname=$adminname --admin-lastname=admin --admin-email=$adminmail --admin-user=$adminname --admin-password=$adminpass --language=en_US --currency=USD --timezone=America/Chicago --use-rewrites=1 --backend-frontname="admin"
chmod -R 0777 var/ pub/ generated/
sudo -u $username php bin/magento cron:install --force
crontab -u $username -l
chmod u-w /home/$username/$domain/public/app/etc
chmod -R 0777 var/ pub/ generated/
echo -e "\e[1;34m + save your admin credentials + \e[0m"
echo -e "\e[1;34m   ===========================   \e[0m"
echo "Magento2 admin user: $adminname" > admin_cred.txt
echo "Magento2 admin pass: $adminpass" >> admin_cred.txt
cat admin_cred.txt
