# ModSecurity Webserver Protection Guide
Welcome to the ModSecurity-Webserver-Protection repository! This repository provides a step-by-step guide on how to use ModSecurity with Apache2 or Nginx web servers to enhance server security. ModSecurity is a popular open-source Web Application Firewall (WAF) that provides protection against various attacks on web applications.

In this guide, I will explore how to use ModSecurity to protect your web server against SQL injection attacks, cross-site scripting (XSS) attacks, and other common web application attacks. I will also cover how to integrate additional security tools like ClamAV, Chkrootkit, Rkhunter, and Fail2ban to further enhance the security of your web server.

This guide is intended for users who have a basic understanding of Linux server administration and are familiar with Apache2 or Nginx web servers. The guide will provide detailed instructions on how to install and configure ModSecurity and other security tools on your web server, as well as how to integrate them with your web server configuration.

I have created this guide in English and German to make it accessible to a wide audience. The guide is organized into sections that cover the installation and configuration of each security tool and their integration with ModSecurity. We will provide detailed explanations, examples, and screenshots to help you follow along with each step.

I hope that this guide will help you enhance the security of your web server and protect your valuable data. If you have any questions or feedback, please feel free to contact us.

## Install mod security for Apache2
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


