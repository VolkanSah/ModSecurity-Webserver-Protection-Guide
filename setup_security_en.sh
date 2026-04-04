#!/bin/bash
# ============================================================
# Security Stack Setup for Ubuntu 24.04 LTS
# Stack: ModSecurity + OWASP CRS + Fail2Ban + ClamAV + RKHunter
#
# Designed for Apache-based setups, but adaptable to:
#   - Any control panel (ISPConfig, Plesk, cPanel, Webmin, none)
#   - Any CDN or no CDN (Cloudflare, Fastly, direct IP, etc.)
#   - Any cert provider (Let's Encrypt, self-signed, commercial)
#   - Any DNS/proxy setup (reverse proxy, bare metal, VPS, etc.)
#
# Requirements: Ubuntu 24.04 LTS, Apache2, root/sudo
# Tested with: ISPConfig + Cloudflare + Let's Encrypt
#
# IMPORTANT: If using a CDN/proxy (e.g. Cloudflare), enable the
#            remoteip module BEFORE going live, or Fail2Ban will
#            ban your CDN's IP ranges instead of real attackers.
#            See end of script for details.
#
# Author: Volkan Sah (Guide) | Script extract for my stack
# ============================================================

set -e  # Exit on error

echo "============================================"
echo " Security Stack Installer - Ubuntu 24.04"
echo "============================================"

# ------------------------------------------------------------
# STEP 1: Update system
# ------------------------------------------------------------
echo "[1/6] Updating system..."
apt-get update && apt-get upgrade -y

# ------------------------------------------------------------
# STEP 2: ModSecurity dependencies
# ------------------------------------------------------------
echo "[2/6] Installing ModSecurity dependencies..."
apt-get install -y \
    build-essential \
    libtool \
    autoconf \
    automake \
    pkg-config \
    libxml2-dev \
    libcurl4-openssl-dev \
    libpcre3-dev \
    libyajl-dev \
    zlib1g-dev \
    liblmdb-dev \
    git \
    apache2 \
    libapache2-mod-security2

# ------------------------------------------------------------
# STEP 3: Enable ModSecurity & install OWASP CRS
# ------------------------------------------------------------
echo "[3/6] Setting up ModSecurity + OWASP Core Rule Set..."

# Enable ModSecurity module
a2enmod security2

# Copy default config
cp /etc/modsecurity/modsecurity.conf-recommended /etc/modsecurity/modsecurity.conf

# Keep SecRuleEngine in DetectionOnly mode for now.
# Switch to "SecRuleEngine On" AFTER verifying no false positives
# in your specific setup (control panel, apps, custom routes, etc.)
sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine DetectionOnly/' /etc/modsecurity/modsecurity.conf

# Install OWASP CRS (Core Rule Set)
# Latest release always at: https://github.com/coreruleset/coreruleset
cd /etc/apache2
git clone https://github.com/coreruleset/coreruleset.git modsecurity-crs
cd modsecurity-crs
cp crs-setup.conf.example crs-setup.conf

# Create symlinks
mkdir -p /etc/apache2/modsecurity.d
ln -sf /etc/apache2/modsecurity-crs/crs-setup.conf /etc/apache2/modsecurity.d/crs-setup.conf
ln -sf /etc/apache2/modsecurity-crs/rules/ /etc/apache2/modsecurity.d/rules

# Write ModSecurity Apache config
cat > /etc/apache2/mods-available/modsecurity.conf << 'EOF'
<IfModule mod_security2.c>
  SecRuleEngine DetectionOnly
  SecRequestBodyAccess On
  SecResponseBodyAccess On
  SecDataDir /var/cache/modsecurity
  IncludeOptional /etc/apache2/modsecurity.d/*.conf
  IncludeOptional /etc/apache2/modsecurity.d/rules/*.conf
</IfModule>
EOF

mkdir -p /var/cache/modsecurity
chown www-data:www-data /var/cache/modsecurity

# Test config and restart Apache
apache2ctl configtest && systemctl restart apache2

echo "   ModSecurity + OWASP CRS installed (Mode: DetectionOnly)"
echo "   NOTE: After verifying your setup, switch to enforcement mode:"
echo "         /etc/modsecurity/modsecurity.conf"
echo "         'SecRuleEngine DetectionOnly' -> 'SecRuleEngine On'"

# ------------------------------------------------------------
# STEP 4: Fail2Ban + ModSecurity integration
# ------------------------------------------------------------
echo "[4/6] Installing and configuring Fail2Ban..."
apt-get install -y fail2ban

# Fail2Ban jail for ModSecurity (Apache audit log)
cat > /etc/fail2ban/jail.d/modsecurity.conf << 'EOF'
[modsec]
enabled  = true
filter   = modsec
logpath  = /var/log/apache2/modsec_audit.log
maxretry = 1
bantime  = 3600
findtime = 600
EOF

# Fail2Ban filter for ModSecurity log format
cat > /etc/fail2ban/filter.d/modsec.conf << 'EOF'
[Definition]
failregex = ^\S+ \S+ \[.*\] \[.*\] \[.*\] \[client <HOST>\] ModSecurity:.*
ignoreregex =
EOF

# SSH protection
# Adjust port if you run SSH on a non-standard port (recommended!)
cat > /etc/fail2ban/jail.d/ssh.conf << 'EOF'
[sshd]
enabled  = true
port     = 22
filter   = sshd
logpath  = /var/log/auth.log
maxretry = 3
bantime  = 7200
findtime = 600
EOF

systemctl enable fail2ban
systemctl restart fail2ban

echo "   Fail2Ban active (SSH + ModSecurity jails)"

# ------------------------------------------------------------
# STEP 5: ClamAV
# ------------------------------------------------------------
echo "[5/6] Installing ClamAV..."
apt-get install -y clamav clamav-daemon

# Update signatures (takes a moment)
systemctl stop clamav-freshclam
freshclam
systemctl start clamav-freshclam
systemctl enable clamav-daemon

echo "   ClamAV installed & signatures updated"

# ------------------------------------------------------------
# STEP 6: RKHunter + Chkrootkit
# ------------------------------------------------------------
echo "[6/6] Installing RKHunter..."
apt-get install -y rkhunter chkrootkit

# Initialize database (must run after each system update!)
rkhunter --update
rkhunter --propupd

# Daily cron job — sends report to root (configure mail alias as needed)
cat > /etc/cron.daily/rkhunter-check << 'EOF'
#!/bin/bash
/usr/bin/rkhunter --check --skip-keypress --quiet --report-warnings-only \
  | mail -s "RKHunter Report $(hostname)" root
EOF
chmod +x /etc/cron.daily/rkhunter-check

echo "   RKHunter + Chkrootkit installed"

# ------------------------------------------------------------
# DONE
# ------------------------------------------------------------
echo ""
echo "============================================"
echo " Installation complete!"
echo "============================================"
echo ""
echo " NEXT STEPS (manual, after your web stack is set up):"
echo ""
echo " 1. Set up your web control panel (if any)"
echo " 2. Configure TLS certificates (Let's Encrypt, certbot, etc.)"
echo " 3. If behind a CDN or reverse proxy (Cloudflare, Nginx, etc.):"
echo "    - Whitelist their IP ranges in Apache"
echo "    - Cloudflare IPs: https://www.cloudflare.com/ips/"
echo "    - Enable remoteip module to log real visitor IPs:"
echo "        a2enmod remoteip"
echo "    - Without this, Fail2Ban WILL ban your proxy's IPs!"
echo " 4. Switch ModSecurity to enforcement mode when ready:"
echo "    /etc/modsecurity/modsecurity.conf"
echo "    -> 'SecRuleEngine On'"
echo " 5. Check Fail2Ban status:"
echo "    fail2ban-client status"
echo " 6. Run first RKHunter scan manually:"
echo "    rkhunter --check"
echo " 7. After system updates, refresh RKHunter baseline:"
echo "    rkhunter --propupd"
echo ""
