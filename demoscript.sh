#!/bin/bash
# ============================================================
# Security Stack Setup für Ubuntu 24.04 LTS
# Stack: ModSecurity + OWASP CRS + Fail2Ban + ClamAV + RKHunter
# Für: Apache (ISPConfig) + Cloudflare + Let's Encrypt
# Autor: Volkan Sah (Guide) | Script-Extrakt für deinen Stack
# ============================================================

set -e  # Bei Fehler abbrechen

echo "============================================"
echo " Security Stack Installer - Ubuntu 24.04"
echo "============================================"

# ------------------------------------------------------------
# SCHRITT 1: System updaten
# ------------------------------------------------------------
echo "[1/6] System updaten..."
apt-get update && apt-get upgrade -y

# ------------------------------------------------------------
# SCHRITT 2: ModSecurity Dependencies
# ------------------------------------------------------------
echo "[2/6] ModSecurity Dependencies installieren..."
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
# SCHRITT 3: ModSecurity aktivieren & OWASP CRS
# ------------------------------------------------------------
echo "[3/6] ModSecurity + OWASP Core Rule Set einrichten..."

# ModSecurity Modul aktivieren
a2enmod security2

# Standard-Config kopieren
cp /etc/modsecurity/modsecurity.conf-recommended /etc/modsecurity/modsecurity.conf

# DetectionOnly -> On (ACHTUNG: erst testen, dann On!)
# Zum Testen erstmal auf DetectionOnly lassen, nach ISPConfig-Setup auf On stellen
sed -i 's/SecRuleEngine DetectionOnly/SecRuleEngine DetectionOnly/' /etc/modsecurity/modsecurity.conf
# Wenn alles läuft, manuell ändern zu: SecRuleEngine On

# OWASP CRS installieren
cd /etc/apache2
git clone https://github.com/coreruleset/coreruleset.git modsecurity-crs
cd modsecurity-crs
cp crs-setup.conf.example crs-setup.conf

# Symlinks setzen
mkdir -p /etc/apache2/modsecurity.d
ln -sf /etc/apache2/modsecurity-crs/crs-setup.conf /etc/apache2/modsecurity.d/crs-setup.conf
ln -sf /etc/apache2/modsecurity-crs/rules/ /etc/apache2/modsecurity.d/rules

# ModSecurity Config für Apache erstellen
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

# Apache Config testen
apache2ctl configtest && systemctl restart apache2

echo "   ModSecurity + OWASP CRS installiert (Modus: DetectionOnly)"
echo "   HINWEIS: Nach ISPConfig-Setup in /etc/modsecurity/modsecurity.conf"
echo "            'SecRuleEngine DetectionOnly' -> 'SecRuleEngine On' ändern!"

# ------------------------------------------------------------
# SCHRITT 4: Fail2Ban + ModSecurity Integration
# ------------------------------------------------------------
echo "[4/6] Fail2Ban installieren & konfigurieren..."
apt-get install -y fail2ban

# Fail2Ban Jail für ModSecurity (Apache)
cat > /etc/fail2ban/jail.d/modsecurity.conf << 'EOF'
[modsec]
enabled  = true
filter   = modsec
logpath  = /var/log/apache2/modsec_audit.log
maxretry = 1
bantime  = 3600
findtime = 600
EOF

# Fail2Ban Filter für ModSecurity Logs
cat > /etc/fail2ban/filter.d/modsec.conf << 'EOF'
[Definition]
failregex = ^\S+ \S+ \[.*\] \[.*\] \[.*\] \[client <HOST>\] ModSecurity:.*
ignoreregex =
EOF

# SSH Schutz (Port 22, kein Key - also absichern!)
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

echo "   Fail2Ban aktiv (SSH + ModSecurity Jails)"

# ------------------------------------------------------------
# SCHRITT 5: ClamAV
# ------------------------------------------------------------
echo "[5/6] ClamAV installieren..."
apt-get install -y clamav clamav-daemon

# Signaturen updaten (dauert kurz)
systemctl stop clamav-freshclam
freshclam
systemctl start clamav-freshclam
systemctl enable clamav-daemon

echo "   ClamAV installiert & Signaturen aktualisiert"

# ------------------------------------------------------------
# SCHRITT 6: RKHunter
# ------------------------------------------------------------
echo "[6/6] RKHunter installieren..."
apt-get install -y rkhunter chkrootkit

# Erste Datenbank initialisieren
rkhunter --update
rkhunter --propupd

# Cronjob für täglichen Scan
cat > /etc/cron.daily/rkhunter-check << 'EOF'
#!/bin/bash
/usr/bin/rkhunter --check --skip-keypress --quiet --report-warnings-only \
  | mail -s "RKHunter Report $(hostname)" root
EOF
chmod +x /etc/cron.daily/rkhunter-check

echo "   RKHunter + Chkrootkit installiert"

# ------------------------------------------------------------
# FERTIG
# ------------------------------------------------------------
echo ""
echo "============================================"
echo " Installation abgeschlossen!"
echo "============================================"
echo ""
echo " NÄCHSTE SCHRITTE (manuell nach ISPConfig):"
echo ""
echo " 1. ISPConfig installieren"
echo " 2. Let's Encrypt Zertifikate einrichten"
echo " 3. Cloudflare IPs in Apache whitelist:"
echo "    https://www.cloudflare.com/ips/"
echo " 4. ModSecurity von DetectionOnly -> On schalten:"
echo "    /etc/modsecurity/modsecurity.conf"
echo " 5. Fail2Ban Status prüfen:"
echo "    fail2ban-client status"
echo " 6. Ersten RKHunter-Scan manuell starten:"
echo "    rkhunter --check"
echo ""
echo " CLOUDFLARE TIPP:"
echo "   Echte IPs durchleiten - in Apache aktivieren:"
echo "   a2enmod remoteip"
echo "   Sonst bannt Fail2Ban Cloudflare-IPs!"
echo ""
