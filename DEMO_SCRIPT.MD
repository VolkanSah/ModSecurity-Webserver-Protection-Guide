# Security Stack Setup Notes
> Ubuntu 24.04 LTS | Apache | ISPConfig | Cloudflare | Let's Encrypt

## Stack Overview
- **ModSecurity** (WAF) — blocks malicious requests at application level
- **OWASP Core Rule Set (CRS)** — production-ready ruleset for ModSecurity
- **Fail2Ban** — bans IPs based on ModSecurity & SSH logs
- **ClamAV** — antivirus for uploaded files
- **RKHunter + Chkrootkit** — rootkit detection

## Installation Order (important!)

```
1. Fresh Ubuntu 24.04 LTS
2. Create admin user, disable root SSH
3. Run setup_security.sh
4. Install ISPConfig
5. Configure Let's Encrypt
6. Set up Cloudflare
7. Switch ModSecurity from DetectionOnly → On
```

## ⚠️ Important Notes

### ModSecurity — Start in DetectionOnly mode
The script sets `SecRuleEngine DetectionOnly` on purpose.  
Do **not** switch to `SecRuleEngine On` before ISPConfig is fully configured —  
OWASP CRS may trigger false positives on ISPConfig's admin panel requests.

After everything is running, switch to On:
```bash
nano /etc/modsecurity/modsecurity.conf
# Change: SecRuleEngine DetectionOnly
# To:     SecRuleEngine On
systemctl restart apache2
```

### Cloudflare — mod_remoteip is critical
If you use Cloudflare, all traffic comes from Cloudflare IPs.  
Without `mod_remoteip`, Fail2Ban will **ban Cloudflare instead of the attacker**.

```bash
a2enmod remoteip
```

Then add Cloudflare's IP ranges to your Apache config:  
→ https://www.cloudflare.com/ips/

### Fail2Ban — SSH without key auth
Since SSH uses password auth (no key), the SSH jail is set to:
- `maxretry = 3`
- `bantime = 7200` (2 hours)

Adjust in `/etc/fail2ban/jail.d/ssh.conf` if needed.

### ClamAV — first update takes time
The `freshclam` run during install downloads the full signature database.  
This can take a few minutes depending on your connection speed — that's normal.

### RKHunter — daily cron report
A daily cron job is installed that sends RKHunter scan results to `root`.  
To receive them by email, configure a mail forwarder or check `/var/mail/root`.

Manual scan anytime:
```bash
rkhunter --check
chkrootkit
```

## After ISPConfig Setup — Checklist

- [ ] ModSecurity switched to `SecRuleEngine On`
- [ ] `mod_remoteip` enabled, Cloudflare IPs whitelisted
- [ ] Let's Encrypt certs active
- [ ] Fail2Ban jails running: `fail2ban-client status`
- [ ] First RKHunter scan clean: `rkhunter --check`
- [ ] ClamAV daemon running: `systemctl status clamav-daemon`
- [ ] OWASP CRS updated: `cd /etc/apache2/modsecurity-crs && git pull`

## Related Resources
- [ModSecurity Webserver Protection Guide](https://github.com/VolkanSah/ModSecurity-Webserver-Protection-Guide)
- [OWASP CRS](https://github.com/coreruleset/coreruleset)
- [Cloudflare IP Ranges](https://www.cloudflare.com/ips/)
- [ISPConfig](https://www.ispconfig.org/)
