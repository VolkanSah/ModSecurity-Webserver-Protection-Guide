# ModSecurity Webserver Protection Guide
Welcome to the ModSecurity-Webserver-Protection repository! This repository provides a step-by-step guide on how to use ModSecurity with Apache2 or Nginx web servers to enhance server security. ModSecurity is a popular open-source Web Application Firewall (WAF) that provides protection against various attacks on web applications.

In this guide, I will explore how to use ModSecurity to protect your web server against SQL injection attacks, cross-site scripting (XSS) attacks, and other common web application attacks. I will also cover how to integrate additional security tools like ClamAV, Chkrootkit, Rkhunter, and Fail2ban to further enhance the security of your web server.

This guide is intended for users who have a basic understanding of Linux server administration and are familiar with Apache2 or Nginx web servers. The guide will provide detailed instructions on how to install and configure ModSecurity and other security tools on your web server, as well as how to integrate them with your web server configuration.

I have created this guide in English and German to make it accessible to a wide audience. The guide is organized into sections that cover the installation and configuration of each security tool and their integration with ModSecurity. We will provide detailed explanations, examples, and screenshots to help you follow along with each step.

I hope that this guide will help you enhance the security of your web server and protect your valuable data. If you have any questions or feedback, please feel free to contact us.

# Install mod security for Apache2
To install ModSecurity on different Linux distributions while using Apache as your web server, follow the steps below.


Note: The instructions provided here assume that you have already installed the Apache web server on your system.
Install prerequisite packages:

### 1. For each distribution, you need to install some prerequisite packages:

- Ubuntu/Debian:
```bash
sudo apt-get update
sudo apt-get install -y build-essential libtool autoconf automake pkg-config libxml2-dev libcurl4-openssl-dev libpcre3-dev libyajl-dev zlib1g-dev liblmdb-dev
```
- Fedora:

```bash
sudo dnf update
sudo dnf install -y @development-tools libtool autoconf automake pkgconfig libxml2-devel libcurl-devel pcre-devel yajl-devel zlib-devel lmdb-devel
```
- BSD:
```bash
sudo pkg update
sudo pkg install -y autoconf automake libtool pkgconf libxml2 libcurl pcre yajl zlib lmdb
```
- Arch Linux:
```bash
sudo pacman -Syu
sudo pacman -S --needed base-devel libxml2 libcurl pcre yajl zlib lmdb
```

- Download and build ModSecurity from source:
```bash
git clone --depth 1 -b v3/master --single-branch https://github.com/SpiderLabs/ModSecurity
cd ModSecurity
git submodule init
git submodule update
./build.sh
./configure
make
sudo make install
```
- Download and build the ModSecurity Apache Connector:
```bash
cd ..
git clone --depth 1 https://github.com/SpiderLabs/ModSecurity-apache.git
cd ModSecurity-apache
./autogen.sh
./configure --with-libmodsecurity=/usr/local/modsecurity
make
sudo make install
```
## Configure Apache to use ModSecurity:
Create a new configuration file for ModSecurity:
```bash
sudo nano /etc/apache2/mods-available/modsecurity.conf
```
```bash
Add the following content to the file:
LoadModule security2_module /usr/lib/apache2/modules/mod_security2.so
<IfModule mod_security2.c>
  SecRuleEngine On
  SecRequestBodyAccess On
  SecResponseBodyAccess On
  SecDataDir /var/cache/modsecurity
  IncludeOptional /etc/apache2/modsecurity.d/*.conf
</IfModule>
```
Create a directory for additional ModSecurity rules:
```bash
sudo mkdir /etc/apache2/modsecurity.d
```
## Enable ModSecurity in Apache:
Ubuntu/Debian:
```bash
sudo a2enmod modsecurity
sudo service apache2 restart

Fedora:
```bash
sudo ln -s /etc/apache2/mods-available/modsecurity.conf /etc/httpd/conf.modules.d/10-modsecurity.conf
sudo systemctl restart httpd
```
BSD:
```bash
echo 'LoadModule security2_module /usr/local/libexec/apache24/mod_security2.so' | sudo tee -a /usr/local/etc/apache24/httpd.conf
sudo service apache24 restart
```
Arch Linux:
```bash
echo 'LoadModule security2_module /usr/lib/httpd/modules/mod_security2.so' | sudo tee -a /etc/httpd/conf/httpd.conf
sudo systemctl restart httpd
```

Configure and download the Core Rule Set (CRS):

    Install the Core Rule Set:
```bash
cd /etc/apache2
sudo git clone https://github.com/coreruleset/coreruleset.git modsecurity-crs
```
Create a symbolic link to the CRS configuration file:
```bash

    sudo ln -s /etc/apache2/modsecurity-crs/crs-setup.conf /etc/apache2/modsecurity.d/crs-setup.conf
    sudo ln -s /etc/apache2/modsecurity-crs/rules/ /etc/apache2/modsecurity.d/rules
```
### Test the Apache configuration:

    Run the following command to test if the configuration is correct:
```bash
sudo apachectl configtest
```
If the output shows "Syntax OK," you can proceed to restart the Apache server:
```bash
sudo systemctl restart apache2
```
Now, ModSecurity should be installed and enabled on your Apache web server. To add custom rules or modify existing ones, you can edit the configuration files located in the /etc/apache2/modsecurity.d/ directory.

# Install mod security for NGINX
Install prerequisite packages:

- Ubuntu/Debian:
```bash
sudo apt-get update
sudo apt-get install -y build-essential libtool autoconf automake pkg-config libxml2-dev libcurl4-openssl-dev libpcre3-dev libyajl-dev zlib1g-dev liblmdb-dev git
```
- Fedora:
```bash
sudo dnf update
sudo dnf install -y @development-tools libtool autoconf automake pkgconfig libxml2-devel libcurl-devel pcre-devel yajl-devel zlib-devel lmdb-devel git
```
- BSD:
```bash
sudo pkg update
sudo pkg install -y autoconf automake libtool pkgconf libxml2 libcurl pcre yajl zlib lmdb git
```
- Arch Linux:
```bash
sudo pacman -Syu
sudo pacman -S --needed base-devel libxml2 libcurl pcre yajl zlib lmdb git
```
- Download and build ModSecurity from source:
```bash
git clone --depth 1 -b v3/master --single-branch https://github.com/SpiderLabs/ModSecurity
cd ModSecurity
git submodule init
git submodule update
./build.sh
./configure
make
sudo make install
```
- Download and build the ModSecurity Nginx Connector:
```bash
cd ..
git clone --depth 1 https://github.com/SpiderLabs/ModSecurity-nginx.git
```
- Download and compile Nginx with ModSecurity module:

- Download the Nginx source code (replace 1.21.4 with the desired version number):
```bash
wget https://nginx.org/download/nginx-1.21.4.tar.gz
tar -xvzf nginx-1.21.4.tar.gz
cd nginx-1.21.4
```

### Compile Nginx with the ModSecurity module:
```bash
./configure --add-dynamic-module=../ModSecurity-nginx
make
sudo make install
```
### Configure Nginx to use ModSecurity:
Create a ModSecurity configuration file (e.g., /etc/nginx/modsecurity.conf) and add the basic ModSecurity configuration:
```bash
SecRuleEngine On
SecRequestBodyAccess On
SecResponseBodyAccess On
SecResponseBodyMimeType text/plain text/html text/xml application/octet-stream
SecDataDir /var/cache/modsecurity
SecAuditEngine RelevantOnly
SecAuditLogRelevantStatus ^(?:5|4\d[^4])$
SecAuditLogParts ABIJDEFHZ
SecAuditLogType Serial
SecAuditLog /var/log/modsecurity_audit.log
```
Edit your Nginx configuration file (usually located at /usr/local/nginx/conf/nginx.conf or /etc/nginx/nginx.conf) and add the following inside the http block:
```bash
modsecurity on;
modsecurity_rules_file /etc/nginx/modsecurity.conf;
```
Additionally, add the following line inside the location block where you want to enable ModSecurity:
```bash
modsecurity_rules_file /etc/nginx/modsecurity_rules.conf;
```
### Configure and download the Core Rule Set (CRS):
Install the Core Rule Set:
```bash
cd /etc/nginx
sudo git clone https://github.com/coreruleset/coreruleset.git modsecurity-crs
```
Create a new Nginx configuration file (e.g., /etc/nginx/modsecurity_rules.conf) and include the CRS rules:
```bash
    include /etc/nginx/modsecurity-crs/crs-setup.conf;
    include /etc/nginx/modsecurity-crs/rules/*.conf;
```
Test the Nginx configuration:

    Run the following command to test if the configuration is correct:
```bash
sudo nginx -t
```
If the output shows "configuration file test is successful," you can proceed to restart the Nginx server:
```bash
        sudo nginx -s reload
```
Now, ModSecurity should be installed and enabled on your Nginx web server. To add custom rules or modify existing ones, you can edit the configuration files located in the /etc/nginx/modsecurity.d/ directory.



