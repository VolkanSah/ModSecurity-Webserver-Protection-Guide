# ModSecurity Webserver Protection Guide 
Welcome to the ModSecurity Webserver Protection repository! This guide provides step-by-step instructions on using ModSecurity with Apache2 or Nginx web servers to enhance security. ModSecurity is a popular open-source Web Application Firewall (WAF) that protects against various web application attacks.

This guide covers using ModSecurity to defend against SQL injection, cross-site scripting (XSS), and other common attacks. It also includes instructions for integrating additional security tools like ClamAV, Chkrootkit, Rkhunter, and Fail2ban to further secure your web server.

Aimed at users with basic Linux server administration skills and familiarity with Apache2 or Nginx, this guide provides detailed installation and configuration steps for ModSecurity and other security tools, along with their integration into your server setup.


I hope this guide helps you enhance your web server's security. If you have any questions or feedback, please contact me. Don't forget to leave a :star:

## Table of content
- [Install mod security for Apache2](#install-mod-security-for-apache2)
  - [Download and build ModSecurity from source](#download-and-build-modsecurity-from-source)
  - [Download and build the ModSecurity Apache Connector](#download-and-build-the-modsecurity-apache-connector)
  - [Configure Apache to use ModSecurity](#configure-apache-to-use-modsecurity)
  - [Enable ModSecurity in Apache](#enable-modsecurity-in-apache)
  - [Configure and download the Core Rule Set (CRS)](#configure-and-download-the-core-rule-set-crs)
  - [Test the Apache configuration](#test-the-apache-configuration)
- [Install mod security for NGINX](#install-mod-security-for-nginx)
  - [Install prerequisite packages](#install-prerequisite-packages)
  - [Download and build ModSecurity from source](#download-and-build-modsecurity-from-source-1)
  - [Download and build the ModSecurity Nginx Connector](#download-and-build-the-modsecurity-nginx-connector)
  - [Download and compile Nginx with ModSecurity module](#download-and-compile-nginx-with-modsecurity-module)
  - [Compile Nginx with the ModSecurity module](#compile-nginx-with-the-modsecurity-module)
  - [Configure Nginx to use ModSecurity](#configure-nginx-to-use-modsecurity)
  - [Configure and download the Core Rule Set (CRS)](#configure-and-download-the-core-rule-set-crs-1)
  - [Test the Nginx configuration](#test-the-nginx-configuration)
- [Configuration for using ClamAV with Apache2](#configuration-for-using-clamav-with-apache2)
- [Configuration for using ClamAV with Nginx](#configuration-for-using-clamav-with-nginx)
- [Use Fail2ban to work with ModSecurity on both Apache and Nginx](#use-fail2ban-to-work-with-modsecurity-on-both-apache-and-nginx)
- [Chkrootkit with Mod_Security](#chkrootkit-with-mod_security)
- [RkHunter with Mod_Security](#rkhunter-with-mod_security)
- [Be carefuly](#be-carefuly)

  


# Install mod security for Apache2
To install ModSecurity on different Linux distributions while using Apache as your web server, follow the steps below.


Note: The instructions provided here assume that you have already installed the Apache web server on your system.
Install prerequisite packages:

### 1. For each distribution, you need to install some prerequisite packages

### Ubuntu/Debian:
```bash
sudo apt-get update
sudo apt-get install -y build-essential libtool autoconf automake pkg-config libxml2-dev libcurl4-openssl-dev libpcre3-dev libyajl-dev zlib1g-dev liblmdb-dev
```

### Fedora:

```bash
sudo dnf update
sudo dnf install -y @development-tools libtool autoconf automake pkgconfig libxml2-devel libcurl-devel pcre-devel yajl-devel zlib-devel lmdb-devel
```
### BSD:
```bash
sudo pkg update
sudo pkg install -y autoconf automake libtool pkgconf libxml2 libcurl pcre yajl zlib lmdb
```
### Arch Linux:
```bash
sudo pacman -Syu
sudo pacman -S --needed base-devel libxml2 libcurl pcre yajl zlib lmdb
```

### Download and build ModSecurity from source:
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
### Download and build the ModSecurity Apache Connector:
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

Add the following content to the file:
LoadModule security2_module /usr/lib/apache2/modules/mod_security2.so
```bash
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
### Ubuntu/Debian:
```bash
sudo a2enmod modsecurity
sudo service apache2 restart
```
### Fedora:
```bash
sudo ln -s /etc/apache2/mods-available/modsecurity.conf /etc/httpd/conf.modules.d/10-modsecurity.conf
sudo systemctl restart httpd
```
BSD:
```bash
echo 'LoadModule security2_module /usr/local/libexec/apache24/mod_security2.so' | sudo tee -a /usr/local/etc/apache24/httpd.conf
sudo service apache24 restart
```
### Arch Linux:
```bash
echo 'LoadModule security2_module /usr/lib/httpd/modules/mod_security2.so' | sudo tee -a /etc/httpd/conf/httpd.conf
sudo systemctl restart httpd
```

## Configure and download the Core Rule Set (CRS):

Install the Core Rule Set:
```bash
cd /etc/apache2
sudo git clone https://github.com/coreruleset/coreruleset.git modsecurity-crs
```
## Create a symbolic link to the CRS configuration file:
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

### Ubuntu/Debian:
```bash
sudo apt-get update
sudo apt-get install -y build-essential libtool autoconf automake pkg-config libxml2-dev libcurl4-openssl-dev libpcre3-dev libyajl-dev zlib1g-dev liblmdb-dev git
```
### Fedora:
```bash
sudo dnf update
sudo dnf install -y @development-tools libtool autoconf automake pkgconfig libxml2-devel libcurl-devel pcre-devel yajl-devel zlib-devel lmdb-devel git
```
### BSD:
```bash
sudo pkg update
sudo pkg install -y autoconf automake libtool pkgconf libxml2 libcurl pcre yajl zlib lmdb git
```
### Arch Linux:
```bash
sudo pacman -Syu
sudo pacman -S --needed base-devel libxml2 libcurl pcre yajl zlib lmdb git
```
### Download and build ModSecurity from source:
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
### Download and build the ModSecurity Nginx Connector:
```bash
cd ..
git clone --depth 1 https://github.com/SpiderLabs/ModSecurity-nginx.git
```
- Download and compile Nginx with ModSecurity module:

### Download the Nginx source code (replace 1.21.4 with the desired version number):
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
### Create a new Nginx configuration file (e.g., /etc/nginx/modsecurity_rules.conf) and include the CRS rules:
```bash
    include /etc/nginx/modsecurity-crs/crs-setup.conf;
    include /etc/nginx/modsecurity-crs/rules/*.conf;
```
### Test the Nginx configuration:

Run the following command to test if the configuration is correct:
```bash
sudo nginx -t
```
If the output shows "configuration file test is successful," you can proceed to restart the Nginx server:
```bash
        sudo nginx -s reload
```
Now, ModSecurity should be installed and enabled on your Nginx web server. To add custom rules or modify existing ones, you can edit the configuration files located in the /etc/nginx/modsecurity.d/ directory.

# Configuration for using ClamAV with Apache2:
These rules scan submitted files for malware by using the "clamscan" command from ClamAV. If a virus is found, the file is blocked and a warning message is issued.

The rules in lines 10-13 scan the uploaded file using ClamAV and block the file if a virus is found. The rules in lines 14-19 allow the upload of files that do not need to be scanned, such as PDF, DOC, and XLS files. The rule in line 20 allows the upload of files that have the "multipart/form-data" content type, which is commonly used for file upload forms.

To configure ModSecurity to use ClamAV as the anti-virus engine, follow these steps:
```bash

SecRule FILES_TMPNAMES "@inspectFile /usr/bin/clamscan" \
    "id:12345,\
    phase:2,\
    t:none,\
    block,\
    msg:'Virus found in file',\
    severity:'CRITICAL',\
    chain"

SecRule FILES_TMPNAMES "!@clamav_scan" \
    "id:12346,\
    phase:2,\
    t:none,\
    pass,\
    chain"

SecRule FILES_TMPNAMES "!@rx \.pdf$" \
    "id:12347,\
    phase:2,\
    t:none,\
    pass,\
    chain"

SecRule FILES_TMPNAMES "!@rx \.doc$" \
    "id:12348,\
    phase:2,\
    t:none,\
    pass,\
    chain"

SecRule FILES_TMPNAMES "!@rx \.xls$" \
    "id:12349,\
    phase:2,\
    t:none,\
    pass"

SecRule REQUEST_HEADERS:Content-Type "!@rx ^multipart/form-data" \
    "id:12350,\
    phase:1,\
    t:none,\
    pass"
```
The comments in the code explain what each rule does. You can customize these rules based on your specific needs.
Save the file and restart Apache:
```bash
sudo systemctl restart apache2
```
With these steps, you have configured ModSecurity to use ClamAV as the anti-virus engine. You can now upload files to your server and ensure that they are automatically checked for malware. If you want every file uploaded to your server to be automatically checked for malware, you can make the following changes to the rules in the ModSecurity configuration file:


Change the rule in line 14 from:
```bash
SecRule FILES_TMPNAMES "!@clamav_scan" \
```
to:
```bash
SecRule FILES_TMPNAMES "!@inspectFile /usr/bin/clamscan" \
```
This will cause every uploaded file to be scanned with ClamAV, regardless of its file type. Remove the rules in lines 15-19 that allow the upload of specific file types. This will ensure that all uploaded files are scanned.

Save the file and restart Apache:
```bash
sudo systemctl restart apache2
```
With these changes, ModSecurity will be configured to scan every uploaded file with ClamAV, regardless of its file type. This will ensure that all files are checked for malware before being stored on your server.

# Configuration for using ClamAV with Nginx:
    Configure ModSecurity to use ClamAV. Here is an example configuration that you can use:
```bash
SecRule REQUEST_BODY \
  "@clamav_scan" \
  "id:12345,\
  phase:2,\
  t:none,\
  block,\
  msg:'Virus found in file',\
  severity:'CRITICAL'"
```
This rule scans the request body with ClamAV and blocks the request if a virus is found. You can customize this rule based on your specific needs.

Configure Nginx to use ModSecurity. Here is an example configuration that you can use:

```bash
http {
  ...
  modsecurity on;
  modsecurity_rules_file /path/to/modsecurity.conf;
  ...
}
```
This configuration enables ModSecurity and specifies the location of the ModSecurity configuration file. You can customize the file path based on where you saved the configuration file.

Save the configuration file and restart Nginx:
```bash
sudo systemctl restart nginx
```
With these steps, you have configured ModSecurity to use ClamAV to scan files for malware in Nginx. You can now upload files to your server and ensure that they are automatically checked for malware.

# use Fail2ban to work with ModSecurity on both Apache and Nginx.

Here are the general steps you can follow:

- Install Fail2ban on your system. The installation process will vary depending on your operating system.

- Configure Fail2ban to read the ModSecurity audit log. You can do this by creating a new Fail2ban jail configuration file that specifies the location of the audit log file. Here is an example configuration file for 
- Apache:
```bash
[modsec]
enabled  = true
filter   = modsec
logpath  = /var/log/apache2/modsec_audit.log
maxretry = 1
```
And here is an example configuration file for Nginx:
```bash
[modsec]
enabled  = true
filter   = modsec
logpath  = /var/log/nginx/modsec_audit.log
maxretry = 1
```
These configurations enable the modsec jail and specify the location of the ModSecurity audit log file.

- Create a Fail2ban filter to parse the ModSecurity audit log. You can create a new filter file in the Fail2ban filter.d directory that contains regular expressions to match the relevant log entries. Here is an example filter file:
```bash

[Definition]
failregex = .*ModSecurity:.*\[id "(?P<id>\d+)".*\] .*\
            Message: Access denied.*\
            Action:.*\
            .*\
            Data: .*\
            Status: (?P<status>\d+)
```
This filter matches ModSecurity log entries that indicate a request was denied due to a ModSecurity rule. You can customize this filter based on your specific needs.

### Configure Fail2ban to use the new filter. You can do this by adding the new filter to the jail.local file. Here is an example configuration for Apache:
```bash
[modsec]
enabled  = true
filter   = modsec
logpath  = /var/log/apache2/modsec_audit.log
maxretry = 1
```
And here is an example configuration for Nginx:
```bash
[modsec]
enabled  = true
filter   = modsec
logpath  = /var/log/nginx/modsec_audit.log
maxretry = 1
```
These configurations enable the modsec jail and specify the location of the ModSecurity audit log file. You can customize the logpath based on where your ModSecurity audit log file is stored.

### Restart Fail2ban to apply the new configuration:
```bash
sudo systemctl restart fail2ban
```
With these steps, you have configured Fail2ban to work with ModSecurity on both Apache and Nginx. When a request is blocked by ModSecurity, Fail2ban will read the audit log and ban the IP address that made the request.

### Chkrootkit with Mod_Security
Chkrootkit is a tool for checking if a system has been compromised by rootkits. While it is not directly related to ModSecurity, you can use it alongside ModSecurity to enhance the security of your web server.

Here are the general steps you can follow to use Chkrootkit with ModSecurity on both Apache and Nginx:

- Install Chkrootkit on your system. The installation process will vary depending on your operating system.

- Create a new ModSecurity rule to check for Chkrootkit warnings. You can create a new rule that checks for the presence of specific strings in the output of the Chkrootkit command. Here is an example rule:
```bash
SecRule ARGS "@rx /usr/bin/chkrootkit" \
  "id:12346,\
  phase:2,\
  t:none,\
  pass,\
  chain"
SecRule RESPONSE_BODY "@rx Warning: Possible \(hacker|trojan|worm\) rootkit activity detected" \
  "id:12347,\
  phase:4,\
  t:none,\
  block,\
  msg:'Possible rootkit activity detected',\
  severity:'CRITICAL'"
```
This rule checks for the presence of the Chkrootkit command in the request arguments, and then checks for the presence of specific warning strings in the response body. If a warning is detected, the rule blocks the request and generates a critical severity message.

- Configure ModSecurity to use the new rule. You can add the new rule to the ModSecurity configuration file, and then reload the configuration to apply the changes.

- Run Chkrootkit regularly to scan for rootkits on your system. You can set up a cron job to run Chkrootkit on a regular basis and send the output to a log file.
- Configure ModSecurity to read the Chkrootkit log file. You can create a new Fail2ban filter that parses the Chkrootkit log file and triggers a ban if specific warning strings are detected.

- Restart your web server to apply the ModSecurity configuration changes.

With these steps, you have configured ModSecurity to work with Chkrootkit on both Apache and Nginx. When a warning is detected by Chkrootkit, ModSecurity will block the request and log a critical severity message. Additionally, you can configure ModSecurity to work with a Fail2ban filter that reads the Chkrootkit log file and triggers a ban if specific warning strings are detected.

## RkHunter with Mod_Security
RKHunter (Rootkit Hunter) is a tool for checking if a system has been compromised by rootkits. Similar to Chkrootkit, you can use RKHunter alongside ModSecurity to enhance the security of your web server.

Here are the general steps you can follow to use RKHunter with ModSecurity on both Apache and Nginx:

- Install RKHunter on your system. The installation process will vary depending on your operating system.

- Create a new ModSecurity rule to check for RKHunter warnings. You can create a new rule that checks for the presence of specific strings in the output of the RKHunter command. Here is an example rule:
```bash
SecRule ARGS "@rx /usr/bin/rkhunter" \
  "id:12348,\
  phase:2,\
  t:none,\
  pass,\
  chain"
SecRule RESPONSE_BODY "@rx Warning: (System\(s\) may have been compromised|Warning: Application\(s\) using \/tmp|Warning: Hidden file found)" \
  "id:12349,\
  phase:4,\
  t:none,\
  block,\
  msg:'Possible rootkit activity detected',\
  severity:'CRITICAL'"
```
This rule checks for the presence of the RKHunter command in the request arguments, and then checks for the presence of specific warning strings in the response body. If a warning is detected, the rule blocks the request and generates a critical severity message.

- Configure ModSecurity to use the new rule. You can add the new rule to the ModSecurity configuration file, and then reload the configuration to apply the changes.

- Run RKHunter regularly to scan for rootkits on your system. You can set up a cron job to run RKHunter on a regular basis and send the output to a log file.

- Configure ModSecurity to read the RKHunter log file. You can create a new Fail2ban filter that parses the RKHunter log file and triggers a ban if specific warning strings are detected.

- Restart your web server to apply the ModSecurity configuration changes.

With these steps, you have configured ModSecurity to work with RKHunter on both Apache and Nginx. When a warning is detected by RKHunter, ModSecurity will block the request and log a critical severity message. Additionally, you can configure ModSecurity to work with a Fail2ban filter that reads the RKHunter log file and triggers a ban if specific warning strings are detected.

## Be carefuly

There are many community-driven projects and resources available online that provide advanced and secure ModSecurity rule files that you can use as a starting point. Here are a few examples:

- OWASP ModSecurity Core Rule Set (CRS): This is a set of rules that are designed to provide basic security protections for web applications. The CRS is continuously updated and maintained by the OWASP ModSecurity Core Rule Set Project, and is available on GitHub.

- Comodo ModSecurity Rules: Comodo is a security company that provides a set of ModSecurity rules that are designed to provide advanced security protections for web applications. These rules are available for free on their website.

- Atomicorp ModSecurity Rules: Atomicorp is a security company that provides a set of ModSecurity rules that are designed to provide advanced security protections for web applications. These rules are available for free on their website.

When using any ModSecurity rule file, it is important to understand the rules and customize them to fit your specific use case. 

## Your Support
If you find this project useful and want to support it, there are several ways to do so:

- If you find the white paper helpful, please ⭐ it on GitHub. This helps make the project more visible and reach more people.
- Become a Follower: If you're interested in updates and future improvements, please follow my GitHub account. This way you'll always stay up-to-date.
- Learn more about my work: I invite you to check out all of my work on GitHub and visit my developer site https://volkansah.github.io. Here you will find detailed information about me and my projects.
- Share the project: If you know someone who could benefit from this project, please share it. The more people who can use it, the better.
**If you appreciate my work and would like to support it, please visit my [GitHub Sponsor page](https://github.com/sponsors/volkansah). Any type of support is warmly welcomed and helps me to further improve and expand my work.**

Thank you for your support! ❤️

##### Copyright S. Volkan Kücükbudak







