#!/bin/sh

sudo apt-get update -y

sudo apt-get install squid -y

sudo apt-get install apache2-utils -y

sudo touch /etc/squid/passwords

sudo chmod 777 /etc/squid/passwords

sudo htpasswd -c -b /etc/squid/passwords login password

sudo mv /etc/squid/squid.conf /etc/squid/squid.conf.original

echo "auth_param basic program /usr/lib/squid/basic_ncsa_auth /etc/squid/passwords
auth_param basic realm Squid proxy-caching web server
auth_param basic credentialsttl 24 hours
auth_param basic casesensitive off
acl authenticated proxy_auth REQUIRED
http_access allow authenticated
http_access deny all
dns_v4_first on
forwarded_for delete
via off
http_port 3201" >> /etc/squid/squid.conf

sudo service squid start

sudo systemctl restart squid.service
