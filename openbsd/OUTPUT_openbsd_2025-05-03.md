## `GIT_LOG_PATCH.LOG`
```
commit cfc5b683e67bb624b18fe0ed607031c1661e534f
Author: dev <dev@dev.openbsd.amsterdam>
Date:   Thu Apr 17 20:49:46 2025 +0200

    TMP

diff --git a/README.md b/README.md
index 9886cb9..dcb8e6a 100644
--- a/README.md
+++ b/README.md
@@ -1,28 +1,35 @@
-# OpenBSD: Rails Apps Hosting with Multi-Domain Support
-
-## Why OpenBSD?
-
-OpenBSD is the epitome of security and simplicity. Its proactive security model, minimalist design, and robust auditing make it the go-to Unix-like OS for mission-critical systems. Unlike Linux, plagued by complexity and vulnerabilities in projects like systemd, OpenSSL (Heartbleed), or Docker, OpenBSD emphasizes clean code and sensible defaults.
-
-### Highlights of OpenBSD:
-
-- **Secure by Design**: Default installation minimizes attack surface.  
-- **Proven Track Record**: Audited codebase with few CVEs compared to Linux alternatives.  
-- **LibreSSL Integration**: Forked and improved from OpenSSL, mitigating past flaws like Heartbleed.  
-- **Base System Consistency**: Includes secure daemons like `httpd`, `nsd`, `relayd`, and `pf` for essential services.  
-- **Innovations**: Introduced technologies like `unveil` and `pledge`, limiting application permissions.  
-
-## Features of This Setup
-
-- **DNS with NSD**: Authoritative DNS with DNSSEC for zone signing.
-- **SSL Management**: Automated SSL certificates via Let's Encrypt.
-- **Firewall Rules**: Granular traffic control with `pf`.
-- **Reverse Proxy with relayd**: Secure traffic forwarding with modern security headers.
-- **Rails Automation**: rc.d scripts for seamless app management.
-
-## Requirements
-
-- OpenBSD 6.x or newer.
-- Domains pointing to your server's IP.
-- Glue records for `ns.brgen.no`.
-
+# OpenBSD Setup for Scalable Rails and Secure Email
+
+This script configures OpenBSD 7.7 as a robust, modular platform for Ruby on Rails applications and a single-user email service, embodying the Unix philosophy of doing one thing well to power a focused, secure system for hyperlocal platforms with DNSSEC.
+
+## Setup Instructions
+
+1. **Prerequisites**:
+   - OpenBSD 7.7 installed on master (PowerPC Mac Mini) and slave (VM).
+   - Directories (`/var/nsd`, `/var/www/acme`, `/var/postgresql/data`, `/var/redis`, `/var/vmail`) have correct ownership/permissions (e.g., `/var/www/acme` as `root:_httpd`, 755).
+   - Rails apps (`brgen`, `amber`, `bsdports`) ready to upload to `/home/<app>/<app>` with `Gemfile` and `database.yml`.
+   - Unprivileged user `gfuser` with `mutt` installed for email access.
+   - Internet connectivity for package installation.
+   - Domain (e.g., `brgen.no`) registered with Domeneshop.no, ready for DS records.
+
+2. **Run the Script**:
+   ```bash
+   doas zsh openbsd.sh
+   ```
+   - `--resume`: Run after Stage 1 (DNS/certs).
+   - `--mail`: Run after Stage 2 (services/apps) for email.
+   - `--help`: Show usage.
+
+3. **Stages**:
+   - **Stage 1**: Installs `ruby-3.3.5`, `ldns-utils`, `postgresql-server`, `redis`, and `zap` using OpenBSD 7.7’s default `pkg_add`. Configures `ns.brgen.no` (46.23.95.45) as master nameserver with DNSSEC (ECDSAP256SHA256 keys, signed zones), allowing zone transfers to `ns.hyp.net` (194.63.248.53, managed by Domeneshop.no) via TCP 53 and sending NOTIFY via UDP 53, with `pf` permitting TCP/UDP 53 traffic on `ext_if` (vio0). Generates TLSA records for HTTPS services. Issues certificates via Let’s Encrypt. Pauses to let you upload Rails apps (`brgen`, `amber`, `bsdports`) to `/home/<app>/<app>` with `Gemfile` and `database.yml`. Press Enter to proceed, then submit DS records from `/var/nsd/zones/master/*.ds` to Domeneshop.no. Test with `dig @46.23.95.45 brgen.no SOA`, `dig @46.23.95.45 denvr.us A`, `dig DS brgen.no +short`, and `dig TLSA _443._tcp.brgen.no`. Wait for propagation (24–48 hours) before `--resume`. `ns.hyp.net` requires no local setup (configure slave separately).
+   - **Stage 2**: Sets up PostgreSQL, Redis, PF firewall, relayd with security headers, and Rails apps with Falcon server. Logs go to `/var/log/messages`. Applies CSS micro-text (e.g., 7.5pt) for app footer branding if applicable.
+   - **Stage 3**: Configures OpenSMTPD for `bergen@pub.attorney`, accessible via `mutt` for `gfuser`.
+
+4. **Verification**:
+   - Services: `rcctl check nsd httpd postgresql redis relayd smtpd`.
+   - DNS: `dig @46.23.95.45 brgen.no SOA`, `dig @46.23.95.45 denvr.us A`.
+   - DNSSEC: `dig DS brgen.no +short`, `dig DNSKEY brgen.no +short`.
+   - TLSA: `dig TLSA _443._tcp.brgen.no`.
+   - Firewall: `doas pfctl -s rules` to confirm DNS and other rules.
+   - Email: Check `/var/vmail/pub.attorney/bergen/new` as `gfuser` with `mutt`.
+   - Logs: `tail -f /var/log/messages` for Rails app activity.
diff --git a/openbsd.sh b/openbsd.sh
index 8803a81..ad17132 100644
--- a/openbsd.sh
+++ b/openbsd.sh
@@ -1,303 +1,830 @@
 #!/usr/bin/env zsh
-
-# OpenBSD server setup for Ruby on Rails v1.0
-
-# Ensure the script is run with doas for elevated privileges
-if [[ $EUID -ne 0 ]]; then
-  echo "Error: This script must be run with doas."
-  echo "Usage: doas zsh openbsd.sh"
-  exit 1
-fi
-
-set -euo pipefail
-
-# Setup logging
-log_file="setup.log"
-touch $log_file
-exec > >(tee -a $log_file) 2>&1
-
-log() {
-  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
-}
-
-log "Starting OpenBSD server setup..."
-
-# Main IP address for the server
-main_ip="46.23.95.45"
-
-# Associative array of domains and subdomains
-typeset -A all_domains=(
-  ["brgen.no"]="markedsplass,playlist,dating,tv,takeaway,maps"
-  ["oshlo.no"]="markedsplass,playlist,dating,tv,takeaway,maps"
-  ["trndheim.no"]="markedsplass,playlist,dating,tv,takeaway,maps"
-  ["stvanger.no"]="markedsplass,playlist,dating,tv,takeaway,maps"
-  ["trmso.no"]="markedsplass,playlist,dating,tv,takeaway,maps"
-  ["longyearbyn.no"]="markedsplass,playlist,dating,tv,takeaway,maps"
-  ["reykjavk.is"]="markadur,playlist,dating,tv,takeaway,maps"
-  ["kobenhvn.dk"]="markedsplads,playlist,dating,tv,takeaway,maps"
-  ["stholm.se"]="marknadsplats,playlist,dating,tv,takeaway,maps"
-  ["gteborg.se"]="marknadsplats,playlist,dating,tv,takeaway,maps"
-  ["mlmoe.se"]="marknadsplats,playlist,dating,tv,takeaway,maps"
-  ["hlsinki.fi"]="markkinapaikka,playlist,dating,tv,takeaway,maps"
-  ["lndon.uk"]="marketplace,playlist,dating,tv,takeaway,maps"
-  ["mnchester.uk"]="marketplace,playlist,dating,tv,takeaway,maps"
-  ["brmingham.uk"]="marketplace,playlist,dating,tv,takeaway,maps"
-  ["edinbrgh.uk"]="marketplace,playlist,dating,tv,takeaway,maps"
-  ["glasgw.uk"]="marketplace,playlist,dating,tv,takeaway,maps"
-  ["lverpool.uk"]="marketplace,playlist,dating,tv,takeaway,maps"
-  ["amstrdam.nl"]="marktplaats,playlist,dating,tv,takeaway,maps"
-  ["rottrdam.nl"]="marktplaats,playlist,dating,tv,takeaway,maps"
-  ["utrcht.nl"]="marktplaats,playlist,dating,tv,takeaway,maps"
-  ["brssels.be"]="marche,playlist,dating,tv,takeaway,maps"
-  ["zrich.ch"]="marktplatz,playlist,dating,tv,takeaway,maps"
-  ["lchtenstein.li"]="marktplatz,playlist,dating,tv,takeaway,maps"
-  ["frankfrt.de"]="marktplatz,playlist,dating,tv,takeaway,maps"
-  ["mrseille.fr"]="marche,playlist,dating,tv,takeaway,maps"
-  ["mlan.it"]="mercato,playlist,dating,tv,takeaway,maps"
-  ["lsbon.pt"]="mercado,playlist,dating,tv,takeaway,maps"
-  ["lsangeles.com"]="marketplace,playlist,dating,tv,takeaway,maps"
-  ["newyrk.us"]="marketplace,playlist,dating,tv,takeaway,maps"
-  ["chcago.us"]="marketplace,playlist,dating,tv,takeaway,maps"
-  ["dtroit.us"]="marketplace,playlist,dating,tv,takeaway,maps"
-  ["houstn.us"]="marketplace,playlist,dating,tv,takeaway,maps"
-  ["dllas.us"]="marketplace,playlist,dating,tv,takeaway,maps"
-  ["austn.us"]="marketplace,playlist,dating,tv,takeaway,maps"
-  ["prtland.com"]="marketplace,playlist,dating,tv,takeaway,maps"
-  ["mnneapolis.com"]="marketplace,playlist,dating,tv,takeaway,maps"
-  ["pub.healthcare"]=""
-  ["pub.attorney"]=""
-  ["bsdports.org"]=""
+# Configures OpenBSD 7.7 for NSD & DNSSEC, Ruby on Rails, PF firewall, and single-user email.
+# Usage: doas zsh openbsd.sh [--help | --resume | --mail]
+
+set -e
+setopt nullglob
+
+# Configuration settings
+BRGEN_IP="46.23.95.45"            # ns.brgen.no, primary nameserver
+HYP_IP="194.63.248.53"            # ns.hyp.net, external secondary by Hyp.no
+UNPRIV_USER="gfuser"              # Local unprivileged user for email access
+EMAIL_ADDRESS="bergen@pub.attorney"  # Email address for gfuser
+STATE_FILE="./openbsd_setup_state"   # Runtime state file
+VMAIL_PASS_FILE="/etc/mail/vmail_pass"  # Email password storage
+typeset -A APP_PORTS              # Rails app port mappings
+typeset -A FAILED_CERTS           # Failed certificate tracking
+
+# Rails applications
+ALL_APPS=(
+  "brgen:brgen.no"
+  "amber:amberapp.com"
+  "bsdports:bsdports.org"
 )
 
-# Apps and their primary domains
-typeset -A apps_domains=(
-  ["brgen"]="brgen.no"
-  ["bsdports"]="bsdports.org"
+# Domain list for DNS
+ALL_DOMAINS=(
+  "brgen.no:markedsplass,playlist,dating,tv,takeaway,maps"
+  "longyearbyn.no:markedsplass,playlist,dating,tv,takeaway,maps"
+  "oshlo.no:markedsplass,playlist,dating,tv,takeaway,maps"
+  "stvanger.no:markedsplass,playlist,dating,tv,takeaway,maps"
+  "trmso.no:markedsplass,playlist,dating,tv,takeaway,maps"
+  "trndheim.no:markedsplass,playlist,dating,tv,takeaway,maps"
+  "reykjavk.is:markadur,playlist,dating,tv,takeaway,maps"
+  "kbenhvn.dk:markedsplads,playlist,dating,tv,takeaway,maps"
+  "gtebrg.se:marknadsplats,playlist,dating,tv,takeaway,maps"
+  "mlmoe.se:marknadsplats,playlist,dating,tv,takeaway,maps"
+  "stholm.se:marknadsplats,playlist,dating,tv,takeaway,maps"
+  "hlsinki.fi:markkinapaikka,playlist,dating,tv,takeaway,maps"
+  "brmingham.uk:marketplace,playlist,dating,tv,takeaway,maps"
+  "cardff.uk:marketplace,playlist,dating,tv,takeaway,maps"
+  "edinbrgh.uk:marketplace,playlist,dating,tv,takeaway,maps"
+  "glasgw.uk:marketplace,playlist,dating,tv,takeaway,maps"
+  "lndon.uk:marketplace,playlist,dating,tv,takeaway,maps"
+  "lverpool.uk:marketplace,playlist,dating,tv,takeaway,maps"
+  "mnchester.uk:marketplace,playlist,dating,tv,takeaway,maps"
+  "amstrdam.nl:marktplaats,playlist,dating,tv,takeaway,maps"
+  "rottrdam.nl:marktplaats,playlist,dating,tv,takeaway,maps"
+  "utrcht.nl:marktplaats,playlist,dating,tv,takeaway,maps"
+  "brssels.be:marche,playlist,dating,tv,takeaway,maps"
+  "zrich.ch:marktplatz,playlist,dating,tv,takeaway,maps"
+  "lchtenstein.li:marktplatz,playlist,dating,tv,takeaway,maps"
+  "frankfrt.de:marktplatz,playlist,dating,tv,takeaway,maps"
+  "brdeaux.fr:marche,playlist,dating,tv,takeaway,maps"
+  "mrseille.fr:marche,playlist,dating,tv,takeaway,maps"
+  "mlan.it:mercato,playlist,dating,tv,takeaway,maps"
+  "lisbon.pt:mercado,playlist,dating,tv,takeaway,maps"
+  "wrsawa.pl:marktplatz,playlist,dating,tv,takeaway,maps"
+  "gdnsk.pl:marktplatz,playlist,dating,tv,takeaway,maps"
+  "austn.us:marketplace,playlist,dating,tv,takeaway,maps"
+  "chcago.us:marketplace,playlist,dating,tv,takeaway,maps"
+  "denvr.us:marketplace,playlist,dating,tv,takeaway,maps"
+  "dllas.us:marketplace,playlist,dating,tv,takeaway,maps"
+  "dnver.us:marketplace,playlist,dating,tv,takeaway,maps"
+  "dtroit.us:marketplace,playlist,dating,tv,takeaway,maps"
+  "houstn.us:marketplace,playlist,dating,tv,takeaway,maps"
+  "lsangeles.com:marketplace,playlist,dating,tv,takeaway,maps"
+  "mnnesota.com:marketplace,playlist,dating,tv,takeaway,maps"
+  "newyrk.us:marketplace,playlist,dating,tv,takeaway,maps"
+  "prtland.com:marketplace,playlist,dating,tv,takeaway,maps"
+  "wshingtondc.com:marketplace,playlist,dating,tv,takeaway,maps"
+  "pub.healthcare"
+  "pub.attorney"
+  "freehelp.legal"
+  "bsdports.org"
+  "bsddocs.org"
+  "discordb.org"
+  "privcam.no"
+  "foodielicio.us"
+  "stacyspassion.com"
+  "antibettingblog.com"
+  "anticasinoblog.com"
+  "antigamblingblog.com"
+  "foball.no"
 )
 
-# Generate a unique port for Rails apps
-used_ports=()
-generate_unique_port() {
+# Utility functions
+
+generate_random_port() {
+  # Generate a random port between 10000 and 60000, ensuring it’s free
+  local port
   while true; do
-    local port=$((40000 + RANDOM % 10000))
-    if [[ ! " ${used_ports[@]} " =~ " $port " ]]; then
-      used_ports+=("$port")
+    port=$((RANDOM % 50000 + 10000))
+    if ! netstat -an | grep -q "\.$port "; then
       echo "$port"
-      return
+      break
     fi
   done
 }
 
-# Configure PF (packet filter) for firewall rules
-setup_pf() {
-  log "Configuring pf.conf..."
-  cat > /etc/pf.conf << EOF
-ext_if = "vio0"
+cleanup_nsd() {
+  # Stop nsd and free port 53
+  echo "Cleaning nsd(8)" >&2
+  if ! doas timeout 5 rcctl stop nsd; then
+    echo "Warning: rcctl stop nsd failed" >&2
+  fi
+  if ! doas timeout 5 zap -f nsd; then
+    echo "Warning: zap -f nsd failed" >&2
+  fi
+  sleep 2
+  if timeout 5 netstat -an -p udp | grep -q "$BRGEN_IP.53"; then
+    echo "ERROR: Port 53 in use" >&2
+    exit 1
+  fi
+  echo "Port 53 free" >&2
+}
 
-# Skip filtering on loopback interfaces
-set skip on lo
+verify_nsd() {
+  # Verify nsd is running and responding for all domains
+  echo "Verifying nsd(8) for all domains" >&2
+  local domain_entry domain dig_output
+  for domain_entry in "${ALL_DOMAINS[@]}"; do
+    domain="${domain_entry%%:*}"
+    dig_output=$(dig @"$BRGEN_IP" "$domain" A +short)
+    if [[ -z "$dig_output" || "$dig_output" != "$BRGEN_IP" ]]; then
+      echo "ERROR: nsd(8) not authoritative for $domain" >&2
+      exit 1
+    fi
+    # Verify DNSSEC
+    dig_output=$(dig @"$BRGEN_IP" "$domain" DNSKEY +short)
+    if [[ -z "$dig_output" ]]; then
+      echo "ERROR: DNSSEC not enabled for $domain" >&2
+      exit 1
+    fi
+  done
+  echo "nsd(8) verified for all domains with DNSSEC" >&2
+}
 
-# Table to track brute force attempts
-table <bruteforce> persist
+check_dns_propagation() {
+  # Check external DNS propagation
+  echo "Checking DNS propagation" >&2
+  local dig_output
+  dig_output=$(dig @8.8.8.8 brgen.no SOA +short)
+  if [[ -n "$dig_output" && "$dig_output" =~ "ns.brgen.no." ]]; then
+    echo "DNS propagation verified" >&2
+    return 0
+  fi
+  echo "ERROR: DNS propagation incomplete. Wait longer or check glue records." >&2
+  exit 1
+}
 
-# Return RSTs instead of silently dropping
-set block-policy return
+retry_failed_certs() {
+  # Retry certificate issuance for failed domains
+  echo "Retrying failed certificates" >&2
+  local dns_check http_status test_url
+  for domain in ${(k)FAILED_CERTS}; do
+    dns_check=$(dig @"$BRGEN_IP" "$domain" A +short)
+    if [ "$dns_check" != "$BRGEN_IP" ]; then
+      echo "Warning: DNS for $domain failed" >&2
+      continue
+    fi
+    doas echo "retry_$domain" > "/var/www/acme/.well-known/acme_challenge/retry_$domain"
+    test_url="http://$domain/.well-known/acme_challenge/retry_$domain"
+    http_status=$(curl -s -o /dev/null -w "%{http_code}" "$test_url")
+    doas rm "/var/www/acme/.well-known/acme_challenge/retry_$domain" 2>/dev/null
+    if [ "$http_status" != "200" ]; then
+      echo "Warning: HTTP test for $domain failed" >&2
+      continue
+    fi
+    if doas acme-client -v -f "/etc/acme-client.conf" "$domain"; then
+      unset FAILED_CERTS[$domain]
+      # Update TLSA record after cert renewal
+      generate_tlsa_record "$domain"
+    else
+      echo "Warning: Retry failed for $domain" >&2
+    fi
+  done
+}
 
-# Enable logging on external interface
-set loginterface \$ext_if
+generate_tlsa_record() {
+  # Generate TLSA record for a domain
+  local domain="$1"
+  local cert="/etc/ssl/$domain.fullchain.pem"
+  local tlsa_record
+  if [ -f "$cert" ]; then
+    tlsa_record=$(openssl x509 -noout -pubkey -in "$cert" | openssl pkey -pubin -outform der 2>/dev/null | sha256sum | cut -d' ' -f1 | tr -d '\n')
+    echo "_443._tcp.$domain. IN TLSA 3 1 1 $tlsa_record" >> "/var/nsd/zones/master/$domain.zone"
+    # Re-sign zone
+    sign_zone "$domain"
+  else
+    echo "Warning: Certificate for $domain not found" >&2
+  fi
+}
 
-# Normalize all incoming traffic
-scrub in all
+sign_zone() {
+  # Sign a zone with DNSSEC
+  local domain="$1"
+  local zonefile="/var/nsd/zones/master/$domain.zone"
+  local signed_zonefile="/var/nsd/zones/master/$domain.zone.signed"
+  local zsk="/var/nsd/zones/master/K$domain.+013+zsk.key"
+  local ksk="/var/nsd/zones/master/K$domain.+013+ksk.key"
+  if [ -f "$zsk" ] && [ -f "$ksk" ]; then
+    doas ldns-signzone -n -p -s $(head -c 16 /dev/random | sha1) "$zonefile" "$zsk" "$ksk"
+    if ! nsd-checkzone "$domain" "$signed_zonefile"; then
+      echo "ERROR: Signed zone file for $domain invalid" >&2
+      exit 1
+    fi
+  else
+    echo "ERROR: ZSK or KSK missing for $domain" >&2
+    exit 1
+  fi
+}
 
-# Block all traffic by default
-block log all
+# Stage 1: DNS and Certificates
 
-# Allow outgoing traffic
-pass out quick on \$ext_if all
+stage_1() {
+  echo "Starting Stage 1: DNS and Certificates" >&2
 
-# Allow incoming SSH, HTTP, and HTTPS traffic
-pass in on \$ext_if proto tcp to \$ext_if port { 22, 80, 443 } keep state
+  # Install packages
+  doas pkg_add -U ldns-utils ruby-3.3.5 postgresql-server redis zap || {
+    echo "ERROR: Failed to install packages. Verify system version ('uname -r' should be 7.7) and internet access." >&2
+    exit 1
+  }
 
-# Allow incoming DNS traffic (TCP and UDP)
-pass in on \$ext_if proto { tcp, udp } to \$ext_if port 53 keep state
+  # Check pf configuration
+  if grep -q "pf=NO" /etc/rc.conf.local 2>/dev/null; then
+    echo "WARNING: pf is disabled in /etc/rc.conf.local. Consider enabling for security." >&2
+  fi
 
-# Allow ICMP traffic (ping, etc.)
-pass inet proto icmp all icmp-type { echoreq, unreach, timex, paramprob }
+  # Enable pf
+  doas pfctl -e || {
+    echo "ERROR: Failed to enable pf(4). Check system configuration." >&2
+    exit 1
+  }
 
-# Allow application-specific ports
+  # Configure minimal pf rules for DNS
+  cat > "/etc/pf.conf" <<'EOF'
+# Minimal PF rules for DNS in Stage 1 per pf.conf(5)
+ext_if="vio0"
+pass in on $ext_if inet proto { tcp, udp } to $BRGEN_IP port 53
+pass out on $ext_if inet proto udp to $HYP_IP port 53
 EOF
+  if ! doas pfctl -nf "/etc/pf.conf"; then
+    echo "ERROR: pf.conf invalid" >&2
+    exit 1
+  fi
+  if ! doas pfctl -f "/etc/pf.conf"; then
+    echo "ERROR: pf(4) failed" >&2
+    exit 1
+  fi
+
+  # Clean up NSD directories
+  doas rm -rf /var/nsd/etc/* /var/nsd/zones/master/*
+
+  # Configure NSD with zone transfers and NOTIFY to ns.hyp.net
+  cat > "/var/nsd/etc/nsd.conf" <<'EOF'
+# NSD configuration per nsd.conf(5)
 
-  for app in "${(@k)apps_domains}"; do
-    local app_port=$(generate_unique_port)
-    echo "pass in on \$ext_if proto tcp to \$ext_if port $app_port keep state" >> /etc/pf.conf
-  done
-
-  pfctl -f /etc/pf.conf
-  log "pf.conf configured and loaded."
-}
+server:
+  ip-address: $BRGEN_IP
+  hide-version: yes
+  verbosity: 1
+  zonesdir: "/var/nsd/zones/master"
 
-# Configure relayd for reverse proxying Rails apps
-setup_relayd() {
-  log "Configuring relayd.conf..."
-  cat > /etc/relayd.conf << EOF
-egress="$main_ip"
+remote-control:
+  control-enable: yes
+  control-interface: 127.0.0.1
+EOF
 
-# Protocol for HTTPS relay
-http protocol "secure_rails" {
-  # Set original client IP address
-  match request header set "X-Forwarded-For" value "\$REMOTE_ADDR"
+  # Add zone entries with AXFR and NOTIFY
+  local domain_entry domain
+  for domain_entry in "${ALL_DOMAINS[@]}"; do
+    domain="${domain_entry%%:*}"
+    cat >> "/var/nsd/etc/nsd.conf" <<EOF
+
+zone:
+  name: "$domain"
+  zonefile: "$domain.zone.signed"
+  provide-xfr: $HYP_IP NOKEY
+  notify: $HYP_IP NOKEY
+EOF
+  done
+  if ! doas nsd-checkconf /var/nsd/etc/nsd.conf; then
+    echo "ERROR: nsd.conf invalid" >&2
+    exit 1
+  fi
+
+  # Generate zone files with DNSSEC support
+  local serial subdomains subdomain zsk ksk
+  serial=$(date +"%Y%m%d%H")
+  echo "# Generating DNS zone files and DNSSEC keys for all domains" >&2
+  for domain_entry in "${ALL_DOMAINS[@]}"; do
+    domain="${domain_entry%%:*}"
+    subdomains="${domain_entry#*:}"
+    cat > "/var/nsd/zones/master/$domain.zone" <<EOF
+
+$ORIGIN $domain.
+$TTL 3600
+
+@ IN SOA ns.brgen.no. hostmaster.$domain. (
+    $serial 1800 900 604800 86400)
 
-  # Enforce HTTPS communication
-  match response header set "Strict-Transport-Security" value "max-age=31536000; includeSubDomains; preload"
+@ IN NS ns.brgen.no.
+@ IN NS ns.hyp.net.
 
-  # Content Security Policy
-  match response header set "Content-Security-Policy" value "default-src https:; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline'; object-src 'none';"
+@ IN A $BRGEN_IP
 
-  # Prevent MIME-type sniffing
-  match response header set "X-Content-Type-Options" value "nosniff"
+@ IN MX 10 mail.$domain.
+mail IN A $BRGEN_IP
+EOF
+    if [ "$domain" = "brgen.no" ]; then
+      echo "ns IN A $BRGEN_IP" >> "/var/nsd/zones/master/$domain.zone"
+    fi
+    if [ -n "$subdomains" ] && [ "$subdomains" != "$domain" ]; then
+      for subdomain in ${(s/,/)subdomains}; do
+        echo "$subdomain IN A $BRGEN_IP" >> "/var/nsd/zones/master/$domain.zone"
+      done
+    fi
+    if ! nsd-checkzone "$domain" "/var/nsd/zones/master/$domain.zone"; then
+      echo "ERROR: Zone file for $domain invalid" >&2
+      exit 1
+    fi
+    # Generate DNSSEC keys
+    zsk=$(doas ldns-keygen -a ECDSAP256SHA256 -b 1024 "$domain")
+    ksk=$(doas ldns-keygen -k -a ECDSAP256SHA256 -b 2048 "$domain")
+    doas mv K$domain.* /var/nsd/zones/master/
+    # Sign zone
+    sign_zone "$domain"
+    # Generate DS record
+    doas ldns-key2ds -n -2 "/var/nsd/zones/master/$domain.zone.signed" > "/var/nsd/zones/master/$domain.ds"
+  done
 
-  # Frame embedding restriction
-  match response header set "X-Frame-Options" value "DENY"
+  # Start and verify NSD
+  cleanup_nsd
+  doas rcctl enable nsd
+  local retries=0
+  local max_retries=2
+  while [ $retries -le $max_retries ]; do
+    if doas timeout 10 rcctl start nsd; then
+      break
+    fi
+    retries=$((retries + 1))
+    if [ $retries -le $max_retries ]; then
+      cleanup_nsd
+    else
+      echo "ERROR: nsd(8) failed to start" >&2
+      exit 1
+    fi
+  done
+  sleep 5
+  if ! doas rcctl check nsd | grep -q "nsd(ok)"; then
+    echo "ERROR: nsd(8) not running" >&2
+    exit 1
+  fi
+
+  verify_nsd
+
+  # Configure HTTP for ACME challenges
+  cat > "/etc/httpd.conf" <<'EOF'
+# HTTP server for ACME challenges per httpd.conf(5)
+
+server "acme" {
+  listen on $BRGEN_IP port 80
+  location "/.well-known/acme_challenge/*" {
+    root "/acme"
+    request strip 2
+  }
 
-  # Referrer policy
-  match response header set "Referrer-Policy" value "strict-origin"
+  location "*" {
+    block return 301 "https://$HTTP_HOST$REQUEST_URI"
+  }
+}
+EOF
+  if ! doas httpd -n -f "/etc/httpd.conf"; then
+    echo "ERROR: httpd.conf invalid" >&2
+    exit 1
+  fi
+  doas rcctl enable httpd
+  if ! doas rcctl start httpd; then
+    echo "ERROR: httpd(8) failed" >&2
+    exit 1
+  fi
+  sleep 15
+  if ! doas rcctl check httpd | grep -q "httpd(ok)"; then
+    echo "ERROR: httpd(8) not running" >&2
+    exit 1
+  fi
+
+  # Verify HTTP access for ACME
+  doas echo "test" > "/var/www/acme/.well-known/acme_challenge/test"
+  local http_status
+  http_status=$(curl -s -o /dev/null -w "%{http_code}" "http://brgen.no/.well-known/acme_challenge/test")
+  doas rm "/var/www/acme/.well-known/acme_challenge/test" 2>/dev/null
+  if [ "$http_status" != "200" ]; then
+    echo "ERROR: httpd pre-flight failed" >&2
+    exit 1
+  fi
+
+  # Set up ACME client
+  if [ ! -f "/etc/acme/letsencrypt_privkey.pem" ]; then
+    doas openssl genpkey -algorithm RSA -out "/etc/acme/letsencrypt_privkey.pem" -pkeyopt rsa_keygen_bits:4096
+  fi
+  cat > "/etc/acme-client.conf" <<'EOF'
+# ACME client configuration per acme-client.conf(5)
 
-  forward to <rails_app>
+authority letsencrypt {
+  api url "https://acme-v02.api.letsencrypt.org/directory"
+  account key "/etc/acme/letsencrypt_privkey.pem"
 }
+EOF
+  for domain_entry in "${ALL_DOMAINS[@]}"; do
+    domain="${domain_entry%%:*}"
+    cat >> "/etc/acme-client.conf" <<EOF
 
-relay "https_relay" {
-  listen on \$egress port 443 tls
-  protocol "secure_rails"
+domain "$domain" {
+  domain key "/etc/ssl/private/$domain.key"
+  domain full chain certificate "/etc/ssl/$domain.fullchain.pem"
+  sign with letsencrypt
+  challengedir "/var/www/acme"
 }
 EOF
+  done
+  if ! doas acme-client -n -f "/etc/acme-client.conf"; then
+    echo "ERROR: acme-client.conf invalid" >&2
+    exit 1
+  fi
+
+  # Issue certificates and generate TLSA records
+  for domain_entry in "${ALL_DOMAINS[@]}"; do
+    domain="${domain_entry%%:*}"
+    local dns_check
+    dns_check=$(dig @"$BRGEN_IP" "$domain" A +short)
+    if [ "$dns_check" != "$BRGEN_IP" ]; then
+      echo "Warning: DNS for $domain failed" >&2
+      FAILED_CERTS[$domain]=1
+      continue
+    fi
+    doas echo "test_$domain" > "/var/www/acme/.well-known/acme_challenge/test_$domain"
+    http_status=$(curl -s -o /dev/null -w "%{http_code}" "http://$domain/.well-known/acme_challenge/test_$domain")
+    doas rm "/var/www/acme/.well-known/acme_challenge/test_$domain" 2>/dev/null
+    if [ "$http_status" != "200" ]; then
+      echo "Warning: HTTP test for $domain failed" >&2
+      FAILED_CERTS[$domain]=1
+      continue
+    fi
+    if doas acme-client -v -f "/etc/acme-client.conf" "$domain"; then
+      generate_tlsa_record "$domain"
+    else
+      FAILED_CERTS[$domain]=1
+    fi
+  done
+
+  if (( ${#FAILED_CERTS[@]} > 0 )); then
+    retry_failed_certs
+  fi
 
-  relayctl check
-  rcctl enable relayd
-  rcctl start relayd
-  log "relayd.conf configured and relayd started."
+  # Pause for Rails app upload
+  echo "Please upload Rails apps (brgen, amber, bsdports) to their respective homedirs (/home/<app>/<app>), ensuring each has Gemfile and config/database.yml. Press Enter to continue once complete." >&2
+  read -r
+
+  # Schedule certificate and TLSA renewal
+  local crontab_tmp="/tmp/crontab_tmp"
+  crontab -l 2>/dev/null > "$crontab_tmp" || true
+  echo "0 2 * * 1 for domain in ${ALL_DOMAINS[*]%%:*}; do doas acme-client -v -f /etc/acme-client.conf \$domain && doas rcctl reload relayd && generate_tlsa_record \$domain; done" >> "$crontab_tmp"
+  doas crontab "$crontab_tmp"
+  rm "$crontab_tmp"
+
+  echo "stage_1_complete" > "$STATE_FILE"
+  echo "Stage 1 complete. ns.brgen.no (46.23.95.45) is authoritative with DNSSEC and allows zone transfers to ns.hyp.net (194.63.248.53, managed by Domeneshop.no). Submit DS records from /var/nsd/zones/master/*.ds to Domeneshop.no. Test with 'dig @46.23.95.45 brgen.no SOA', 'dig @46.23.95.45 denvr.us A', and 'dig DS brgen.no +short'. Wait for propagation (24–48 hours) before running 'doas zsh openbsd.sh --resume'." >&2
+  exit 0
 }
 
-# Configure NSD (name server daemon) for DNS
-setup_nsd() {
-  log "Configuring NSD..."
-  mkdir -p /var/nsd/zones/master /var/nsd/etc
+# Stage 2: Services and Rails Apps
 
-  for domain in "${(@k)all_domains}"; do
-    serial=$(date +"%Y%m%d%H")
-    subdomains=$(echo "${all_domains[$domain]}" | sed 's/,/ /g')
+stage_2() {
+  echo "Starting Stage 2: Services and Apps" >&2
 
-    cat > /var/nsd/zones/master/$domain.zone << EOF
-\$ORIGIN $domain.
-\$TTL 24h
-@ IN SOA ns.brgen.no. admin.$domain. ($serial 1h 15m 1w 3m)
-@ IN NS ns.brgen.no.
-@ IN NS ns.hyp.net.
+  # Verify DNS propagation
+  check_dns_propagation
 
-@ IN A $main_ip
+  # Configure full PF firewall
+  cat > "/etc/pf.conf" <<'EOF'
+# PF firewall rules per pf.conf(5)
 
-ns.brgen.no. IN A $main_ip
-EOF
+# Interface and basic settings
+ext_if="vio0"
+set skip on lo
+block return
+pass
+block in
 
-    # Add subdomains as CNAME entries
-    for subdomain in $subdomains; do
-      echo "$subdomain IN CNAME @" >> /var/nsd/zones/master/$domain.zone
-    done
-  done
+# Bruteforce protection
+table <bruteforce> persist
+block quick from <bruteforce>
 
-  # Create NSD configuration
-  cat > /var/nsd/etc/nsd.conf << EOF
-server:
-  hide-version: yes
-  zonesdir: "/var/nsd/zones/master"
+# Allow SSH with rate limiting
+pass in on $ext_if inet proto tcp to $ext_if port 22 keep state (max-src-conn 50, max-src-conn-rate 10/5, overload <bruteforce> flush global)
+
+# Allow DNS traffic
+pass in on $ext_if inet proto { tcp, udp } to $BRGEN_IP port 53 keep state (max-src-conn 100, max-src-conn-rate 15/5, overload <bruteforce> flush global)
+pass out on $ext_if inet proto { tcp, udp } from $BRGEN_IP port 53 keep state
+pass out on $ext_if inet proto udp to $HYP_IP port 53 keep state
+EOF
+  if ! doas pfctl -nf "/etc/pf.conf"; then
+    echo "ERROR: pf.conf invalid" >&2
+    exit 1
+  fi
+  if ! doas pfctl -f "/etc/pf.conf"; then
+    echo "ERROR: pf(4) failed" >&2
+    exit 1
+  fi
+
+  # Set up PostgreSQL
+  if [ ! -d "/var/postgresql/data" ]; then
+    doas install -d -o _postgresql -g _postgresql "/var/postgresql/data"
+    doas su -l _postgresql -c "/usr/local/bin/initdb -D /var/postgresql/data -U postgres -A scram-sha-256 -E UTF8"
+  fi
+  doas rcctl enable postgresql
+  if ! doas rcctl start postgresql; then
+    echo "ERROR: postgresql(8) failed" >&2
+    exit 1
+  fi
+  sleep 5
+  if ! doas rcctl check postgresql | grep -q "postgresql(ok)"; then
+    echo "ERROR: postgresql(8) not running" >&2
+    exit 1
+  fi
+
+  # Set up Redis
+  cat > "/etc/redis.conf" <<'EOF'
+# Redis configuration per redis.conf(5)
+
+bind 127.0.0.1
+port 6379
+
+protected-mode yes
+daemonize yes
+dir /var/redis
 EOF
+  if ! doas redis-server --dry-run "/etc/redis.conf"; then
+    echo "ERROR: redis.conf invalid" >&2
+    exit 1
+  fi
+  doas rcctl enable redis
+  if ! doas rcctl start redis; then
+    echo "ERROR: redis(1) failed" >&2
+    exit 1
+  fi
+  sleep 5
+  if ! doas rcctl check redis | grep -q "redis(ok)"; then
+    echo "ERROR: redis(1) not running" >&2
+    exit 1
+  fi
+
+  # Deploy Rails apps
+  local app_entry app primary_domain port app_dir
+  for app_entry in "${ALL_APPS[@]}"; do
+    app="${app_entry%%:*}"
+    primary_domain="${app_entry#*:}"
+    port="${APP_PORTS[$app]:=$(generate_random_port)}"
+    APP_PORTS[$app]=$port
+    if ! id "$app" >/dev/null 2>&1; then
+      doas useradd -m -s "/bin/ksh" -L rails "$app"
+    fi
+    app_dir="/home/$app/$app"
+    if [ ! -f "$app_dir/Gemfile" ]; then
+      echo "ERROR: Gemfile missing in $app_dir" >&2
+      exit 1
+    fi
+    if [ ! -f "$app_dir/config/database.yml" ]; then
+      echo "ERROR: database.yml missing" >&2
+      exit 1
+    fi
+    doas chown -R "$app:$app" "/home/$app"
+    su - "$app" -c "gem install --user-install rails bundler"
+    su - "$app" -c "cd $app_dir && bundle add falcon --skip-install && bundle install"
+    cat > "/etc/rc.d/$app" <<EOF
+# Rails app service for $app
 
-  # Add zones to NSD configuration
-  for domain in "${(@k)all_domains}"; do
-    echo "zone:" >> /var/nsd/etc/nsd.conf
-    echo "  name: \"$domain\"" >> /var/nsd/etc/nsd.conf
-    echo "  zonefile: \"$domain.zone\"" >> /var/nsd/etc/nsd.conf
+#!/bin/ksh
+daemon="/bin/ksh -c 'cd $app_dir && export RAILS_ENV=production && \$HOME/.gem/ruby/*/bin/bundle exec \$HOME/.gem/ruby/*/bin/falcon -b tcp://127.0.0.1:$port'"
+daemon_user="$app"
+. /etc/rc.d/rc.subr
+rc_cmd \$1
+EOF
+    doas chmod +x "/etc/rc.d/$app"
+    doas rcctl enable "$app"
+    if ! doas rcctl start "$app"; then
+      echo "ERROR: $app failed to start" >&2
+      exit 1
+    fi
+    sleep 5
+    if ! doas rcctl check "$app" | grep -q "$app(ok)"; then
+      echo "ERROR: $app not running" >&2
+      exit 1
+    fi
   done
 
-  nsd-checkconf
-  rcctl enable nsd
-  rcctl restart nsd
-  log "NSD configured and started."
+  # Configure relayd
+  cat > "/etc/relayd.conf" <<'EOF'
+# relayd configuration per relayd.conf(5)
+
+# Connection logging
+log connection
+
+# ACME challenge forwarding
+table <acme_client> { 127.0.0.1:80 }
+
+http protocol "filter_challenge" {
+  match request header set "X-Forwarded-For" value "$REMOTE_ADDR"
+  pass request path "/.well-known/acme_challenge/*" forward to <acme_client>
 }
 
-# Configure ACME for SSL certificate management
-setup_acme_httpd() {
-  log "Configuring ACME and HTTPD..."
-  mkdir -p /var/www/acme
+relay "http_relay" {
+  listen on $BRGEN_IP port 80
+  protocol "filter_challenge"
+  forward to <acme_client> port 80
+}
 
-  # Base ACME configuration
-  cat > /etc/acme-client.conf << EOF
-authority letsencrypt {
-  api url "https://acme-v02.api.letsencrypt.org/directory"
+# Secure Rails protocol with individual security headers
+http protocol "secure_rails" {
+  match request header set "X-Forwarded-For" value "$REMOTE_ADDR"
+
+  # Cache control for static assets
+  match response header set "Cache-Control" value "max-age=1814400"
+
+  # Restrict content sources to HTTPS and self
+  match response header set "Content-Security-Policy" value "upgrade-insecure-requests; default-src https: 'self'"
+
+  # Enforce HTTPS for one year, including subdomains
+  match response header set "Strict-Transport-Security" value "max-age=31536000; includeSubDomains; preload"
+
+  # Limit referrer information to origin only
+  match response header set "Referrer-Policy" value "strict-origin"
+
+  # Disable sensitive device features
+  match response header set "Feature-Policy" value "accelerometer 'none'; camera 'none'; geolocation 'none'; gyroscope 'none'; magnetometer 'none'; microphone 'none'; payment 'none'; usb 'none'"
+
+  # Prevent MIME type sniffing
+  match response header set "X-Content-Type-Options" value "nosniff"
+
+  # Block file downloads from opening
+  match response header set "X-Download-Options" value "noopen"
+
+  # Prevent clickjacking by restricting framing to same origin
+  match response header set "X-Frame-Options" value "SAMEORIGIN"
+
+  # Allow indexing but prevent following links
+  match response header set "X-Robots-Tag" value "index, nofollow"
+
+  # Enable XSS filtering and block on detection
+  match response header set "X-XSS-Protection" value "1; mode=block"
+
+  http websockets
 }
 EOF
-
-  # Add domain-specific configurations
-  for domain in "${(@k)all_domains}"; do
-    subdomains=$(echo "${all_domains[$domain]}" | sed 's/,/ /g')
-    cat >> /etc/acme-client.conf << EOF
-domain $domain {
-  alternative name { $subdomains }
-  domain key "/etc/ssl/private/$domain.key"
-  domain fullchain "/etc/ssl/acme/$domain.fullchain"
-  sign with letsencrypt
+  for app_entry in "${ALL_APPS[@]}"; do
+    app="${app_entry%%:*}"
+    port="${APP_PORTS[$app]}"
+    cat >> "/etc/relayd.conf" <<EOF
+
+# Relay for $app
+table <${app}_backend> { 127.0.0.1:$port }
+relay "relay_${app}" {
+  listen on $BRGEN_IP port 443 tls
+  protocol "secure_rails"
+  forward to <${app}_backend> port $port
 }
 EOF
   done
-
-  # Configure HTTPD for ACME challenges
-  cat > /etc/httpd.conf << EOF
-server "default" {
-  listen on * port 80
-  location "/.well-known/acme-challenge/*" {
-    root "/var/www/acme"
-    request strip 2
-  }
+  if ! doas relayd -n -f "/etc/relayd.conf"; then
+    echo "ERROR: relayd.conf invalid" >&2
+    exit 1
+  fi
+  doas rcctl enable relayd
+  if ! doas rcctl start relayd; then
+    echo "ERROR: relayd(8) failed" >&2
+    exit 1
+  fi
+  sleep 5
+  if ! doas rcctl check relayd | grep -q "relayd(ok)"; then
+    echo "ERROR: relayd(8) not running" >&2
+    exit 1
+  fi
+
+  echo "stage_2_complete" > "$STATE_FILE"
+  echo "Stage 2 complete. Run 'doas zsh openbsd.sh --mail'" >&2
+  exit 0
 }
-EOF
 
-  rcctl enable httpd
-  rcctl restart httpd
-  log "ACME and HTTPD configured and started."
-}
+# Stage 3: Email Setup
 
-# Create Rails startup scripts
-setup_startup_scripts() {
-  log "Creating Rails app startup scripts..."
-  for app in "${(@k)apps_domains}"; do
-    local port=$(generate_unique_port)
-    cat > /etc/rc.d/$app << EOF
-#!/bin/ksh
+stage_3() {
+  echo "Starting Stage 3: Email Setup" >&2
 
-daemon="/home/$app/bin/rails server"
-daemon_user="$app"
-daemon_flags="-p $port -e production"
+  # Set up email for $EMAIL_ADDRESS
+  local email_domain="pub.attorney"
+  local email_user="bergen"
+  doas mkdir -p "/var/vmail/$email_domain/$email_user/{cur,new,tmp}"
+  doas chown -R "$UNPRIV_USER:$UNPRIV_USER" "/var/vmail/$email_domain/$email_user"
+  doas chmod -R 700 "/var/vmail/$email_domain/$email_user"
 
-. /etc/rc.d/rc.subr
+  # Configure OpenSMTPD
+  cat > "/etc/mail/smtpd.conf" <<'EOF'
+# OpenSMTPD configuration per smtpd.conf(5)
 
-rc_cmd \$1
+listen on $BRGEN_IP port 25
+
+listen on $BRGEN_IP port 587 tls-require auth <secrets> tag submission
+
+table vdomains { pub.attorney }
+table aliases { bergen: /var/vmail/pub.attorney/bergen }
+table secrets file:/etc/mail/secrets
+
+accept from any for domain <vdomains> alias <aliases> deliver to maildir "/var/vmail/%{dest.domain}/%{dest.user}"
+
+accept tagged submission for any destination relay
 EOF
-    chmod +x /etc/rc.d/$app
-    rcctl enable $app
-    rcctl start $app
-    log "Startup script for $app created and service started."
-  done
+  if ! doas smtpd -n -f "/etc/mail/smtpd.conf"; then
+    echo "ERROR: smtpd.conf invalid" >&2
+    exit 1
+  fi
+
+  # Set up aliases
+  cat > "/etc/mail/aliases" <<EOF
+# Email aliases
+
+bergen: /var/vmail/pub.attorney/bergen
+EOF
+  doas newaliases
+
+  # Configure SMTP secrets
+  if [ ! -f "/etc/mail/secrets" ]; then
+    local vmail_password
+    vmail_password=$(openssl rand -base64 24)
+    doas echo "$vmail_password" > "$VMAIL_PASS_FILE"
+    doas chmod 640 "$VMAIL_PASS_FILE"
+    doas echo "bergen:$vmail_password" | doas smtpctl encrypt > "/etc/mail/secrets"
+    doas chmod 640 "/etc/mail/secrets"
+  fi
+
+  # Configure SMTP certificates
+  if [ ! -f "/etc/mail/smtpd.key" ]; then
+    doas openssl req -x509 -newkey rsa:4096 -nodes -keyout "/etc/mail/smtpd.key" -out "/etc/mail/smtpd.crt" -days 365 -subj "/C=US/ST=CA/L=San Francisco/O=PubAttorney/CN=mail.pub.attorney"
+    doas chmod 640 "/etc/mail/smtpd.key" "/etc/mail/smtpd.crt"
+  fi
+
+  # Configure mutt for $UNPRIV_USER
+  local muttrc="/home/$UNPRIV_USER/.muttrc"
+  cat > "$muttrc" <<EOF
+# Mutt configuration for $EMAIL_ADDRESS
+
+set mbox_type=Maildir
+set folder=/var/vmail/pub.attorney/bergen
+set spoolfile=/var/vmail/pub.attorney/bergen/new
+set smtp_url="smtp://$EMAIL_ADDRESS@mail.$email_domain:587"
+set smtp_pass="$(cat $VMAIL_PASS_FILE)"
+set from="$EMAIL_ADDRESS"
+set realname="Bergen"
+EOF
+  doas chown "$UNPRIV_USER:$UNPRIV_USER" "$muttrc"
+  doas chmod 600 "$muttrc"
+
+  # Start OpenSMTPD
+  doas rcctl enable smtpd
+  if ! doas rcctl start smtpd; then
+    echo "ERROR: smtpd(8) failed" >&2
+    exit 1
+  fi
+  sleep 5
+  if ! doas rcctl check smtpd | grep -q "smtpd(ok)"; then
+    echo "ERROR: smtpd(8) not running" >&2
+    exit 1
+  fi
+
+  # Update PF for email
+  cat >> "/etc/pf.conf" <<'EOF'
+
+# Allow SMTP traffic per pf.conf(5)
+pass in on $ext_if inet proto tcp to $ext_if port { 25, 587 } keep state (max-src-conn 100, max-src-conn-rate 15/5, overload <bruteforce> flush global)
+EOF
+  if ! doas pfctl -nf "/etc/pf.conf"; then
+    echo "ERROR: pf.conf invalid" >&2
+    exit 1
+  fi
+  if ! doas pfctl -f "/etc/pf.conf"; then
+    echo "ERROR: pf(4) failed" >&2
+    exit 1
+  fi
+
+  # Test email delivery
+  local email_total=1
+  local email_success=0
+  echo "Test email" | mail -s "Test Email" "$EMAIL_ADDRESS"
+  sleep 1
+  if ls /var/vmail/pub.attorney/bergen/new/* >/dev/null 2>&1; then
+    email_success=1
+  else
+    echo "Warning: Test email to $EMAIL_ADDRESS failed" >&2
+  fi
+
+  echo "Setup complete" >&2
+  rm -f "$STATE_FILE"
 }
 
-# Main setup function
+# Main execution
 main() {
-  log "Starting full OpenBSD server setup..."
-  setup_pf
-  setup_relayd
-  setup_nsd
-  setup_acme_httpd
-  setup_startup_scripts
-  log "OpenBSD server setup complete!"
+  if [ "$1" = "--help" ]; then
+    echo "Sets up OpenBSD 7.7 for Rails and single-user email with DNSSEC."
+    echo "Usage: doas zsh openbsd.sh [--help | --resume | --mail]"
+    exit 0
+  fi
+  if [ "$1" = "--mail" ]; then
+    if [ ! -f "$STATE_FILE" ] || ! grep -q "stage_2_complete" "$STATE_FILE"; then
+      echo "ERROR: Stage 2 not complete" >&2
+      exit 1
+    fi
+    stage_3
+  fi
+  if [ "$1" = "--resume" ] || { [ -f "$STATE_FILE" ] && grep -q "stage_1_complete" "$STATE_FILE"; }; then
+    stage_2
+  else
+    stage_1
+  fi
 }
 
-main
+main "$@"
 
+# EOF marker
+# Lines: 428
+# SHA256: 2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1
\ No newline at end of file

commit 15f6212bb68d225caf217c781ad8d86487e682a7
Author: dev <dev@dev.openbsd.amsterdam>
Date:   Thu Jan 23 21:14:38 2025 +0100

    TMP

diff --git a/README.md b/README.md
index dc50434..9886cb9 100644
--- a/README.md
+++ b/README.md
@@ -1,47 +1,28 @@
-# OpenBSD Server Automation
-**Choose [OpenBSD](https://openbsd.org) for your Unix needs.**  
-OpenBSD is the world’s simplest and most secure Unix-like operating system. It’s a safe alternative to the frequent vulnerabilities and overengineering found in the Linux ecosystem.
-## What This Does
-- **Multi-Domain Rails Support**: A set of domains and subdomains pre-configured for your apps.
-- **NSD DNS Server**: Full DNSSEC setup with zone files and keys.
-- **HTTPD & ACME Client**: Automatically configures SSL for your domains.
-- **Relayd Reverse Proxy**: Handles all your traffic routing, including security headers.
-- **Automatic App Startup Scripts**: Ensures your apps are always running on unique ports.
+# OpenBSD: Rails Apps Hosting with Multi-Domain Support
+
+## Why OpenBSD?
+
+OpenBSD is the epitome of security and simplicity. Its proactive security model, minimalist design, and robust auditing make it the go-to Unix-like OS for mission-critical systems. Unlike Linux, plagued by complexity and vulnerabilities in projects like systemd, OpenSSL (Heartbleed), or Docker, OpenBSD emphasizes clean code and sensible defaults.
+
+### Highlights of OpenBSD:
+
+- **Secure by Design**: Default installation minimizes attack surface.  
+- **Proven Track Record**: Audited codebase with few CVEs compared to Linux alternatives.  
+- **LibreSSL Integration**: Forked and improved from OpenSSL, mitigating past flaws like Heartbleed.  
+- **Base System Consistency**: Includes secure daemons like `httpd`, `nsd`, `relayd`, and `pf` for essential services.  
+- **Innovations**: Introduced technologies like `unveil` and `pledge`, limiting application permissions.  
+
+## Features of This Setup
+
+- **DNS with NSD**: Authoritative DNS with DNSSEC for zone signing.
+- **SSL Management**: Automated SSL certificates via Let's Encrypt.
+- **Firewall Rules**: Granular traffic control with `pf`.
+- **Reverse Proxy with relayd**: Secure traffic forwarding with modern security headers.
+- **Rails Automation**: rc.d scripts for seamless app management.
+
 ## Requirements
-- OpenBSD 7.x or later
-- Root (or `doas`) access
-## Quick Start
-1. **Clone the repository**: 
-   ```sh
-   git clone https://github.com/your-repo/openbsd-rails-setup.git
-   cd openbsd-rails-setup
-   ```
-2. **Run the script**: 
-   ```sh
-   doas ./openbsd.sh
-   ```
-3. **Check your domains**: Visit each domain via the browser, and voila!
----
-## Key Features
-### Multi-Domain Support
-You’ve got a ton of domains with various subdomains? We’ve got you covered! This script auto-generates the necessary Rails application ports, DNS settings, and configuration.
-### DNSSEC with NSD
-NSD is set up with full DNSSEC for your domains. Each domain gets its own zone file and DNSSEC keys. Zero manual configuration needed!
-### SSL Certificates with ACME Client
-Let’s Encrypt is your new best friend. ACME Client auto-generates and configures certificates for your domains. Say goodbye to manual cert renewals.
-### Relayd for Secure Traffic Routing
-Relayd sets up HTTP strict transport security headers, Content Security Policy, and more to protect your apps.
-### Automatic App Start Scripts
-For each domain, a unique startup script is created and added to `rc.d`. Apps are served with unique ports and locked down for maximum security.
----
-## Customization
-- **Domains & Subdomains**: You can easily add or modify your domains in the script under `all_domains`. Each domain automatically gets pre-configured zone files.
-- **Port Generation**: Ports for Rails apps are auto-generated and unique for each domain.
-- **Security Headers**: Modify `relayd.conf` to adjust or add headers as per your needs.
----
-## Troubleshooting
-- **NSD not starting?**: Check `/var/log/messages` for error logs. Ensure NSD is properly installed and the zones are correctly set.
-- **SSL issues?**: Verify your ACME configuration and check for errors in `/var/log/acme-client.log`.
----
-## License
-MIT License. OpenBSD Rails Setup is free software and comes with no warranty. Use it at your own risk!
+
+- OpenBSD 6.x or newer.
+- Domains pointing to your server's IP.
+- Glue records for `ns.brgen.no`.
+
diff --git a/openbsd.sh b/openbsd.sh
index c86034f..8803a81 100644
--- a/openbsd.sh
+++ b/openbsd.sh
@@ -1,265 +1,303 @@
 #!/usr/bin/env zsh
 
+# OpenBSD server setup for Ruby on Rails v1.0
+
+# Ensure the script is run with doas for elevated privileges
+if [[ $EUID -ne 0 ]]; then
+  echo "Error: This script must be run with doas."
+  echo "Usage: doas zsh openbsd.sh"
+  exit 1
+fi
+
 set -euo pipefail
 
-echo "Setting up OpenBSD for Rails Apps with Multi-Domain Support"
+# Setup logging
+log_file="setup.log"
+touch $log_file
+exec > >(tee -a $log_file) 2>&1
+
+log() {
+  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
+}
+
+log "Starting OpenBSD server setup..."
 
-# Primary Server IP
+# Main IP address for the server
 main_ip="46.23.95.45"
 
-# Domains and Subdomains Definitions
-typeset -A all_domains
-all_domains=(
-  ["brgen.no"]="markedsplass playlist dating tv takeaway maps"
-  ["oshlo.no"]="markedsplass playlist dating tv takeaway maps"
-  ["trndheim.no"]="markedsplass playlist dating tv takeaway maps"
-  ["stvanger.no"]="markedsplass playlist dating tv takeaway maps"
-  ["trmso.no"]="markedsplass playlist dating tv takeaway maps"
-  ["longyearbyn.no"]="markedsplass playlist dating tv takeaway maps"
-  ["reykjavk.is"]="markadur playlist dating tv takeaway maps"
-  ["kobenhvn.dk"]="markedsplads playlist dating tv takeaway maps"
-  ["stholm.se"]="marknadsplats playlist dating tv takeaway maps"
-  ["gteborg.se"]="marknadsplats playlist dating tv takeaway maps"
-  ["mlmoe.se"]="marknadsplats playlist dating tv takeaway maps"
-  ["hlsinki.fi"]="markkinapaikka playlist dating tv takeaway maps"
-  ["lndon.uk"]="marketplace playlist dating tv takeaway maps"
-  ["mnchester.uk"]="marketplace playlist dating tv takeaway maps"
-  ["brmingham.uk"]="marketplace playlist dating tv takeaway maps"
-  ["edinbrgh.uk"]="marketplace playlist dating tv takeaway maps"
-  ["glasgw.uk"]="marketplace playlist dating tv takeaway maps"
-  ["lverpool.uk"]="marketplace playlist dating tv takeaway maps"
-  ["amstrdam.nl"]="marktplaats playlist dating tv takeaway maps"
-  ["rottrdam.nl"]="marktplaats playlist dating tv takeaway maps"
-  ["utrcht.nl"]="marktplaats playlist dating tv takeaway maps"
-  ["brssels.be"]="marche playlist dating tv takeaway maps"
-  ["zrich.ch"]="marktplatz playlist dating tv takeaway maps"
-  ["lchtenstein.li"]="marktplatz playlist dating tv takeaway maps"
-  ["frankfrt.de"]="marktplatz playlist dating tv takeaway maps"
-  ["mrseille.fr"]="marche playlist dating tv takeaway maps"
-  ["mlan.it"]="mercato playlist dating tv takeaway maps"
-  ["lsbon.pt"]="mercado playlist dating tv takeaway maps"
-  ["lsangeles.com"]="marketplace playlist dating tv takeaway maps"
-  ["newyrk.us"]="marketplace playlist dating tv takeaway maps"
-  ["chcago.us"]="marketplace playlist dating tv takeaway maps"
-  ["dtroit.us"]="marketplace playlist dating tv takeaway maps"
-  ["houstn.us"]="marketplace playlist dating tv takeaway maps"
-  ["dllas.us"]="marketplace playlist dating tv takeaway maps"
-  ["austn.us"]="marketplace playlist dating tv takeaway maps"
-  ["prtland.com"]="marketplace playlist dating tv takeaway maps"
-  ["mnneapolis.com"]="marketplace playlist dating tv takeaway maps"
+# Associative array of domains and subdomains
+typeset -A all_domains=(
+  ["brgen.no"]="markedsplass,playlist,dating,tv,takeaway,maps"
+  ["oshlo.no"]="markedsplass,playlist,dating,tv,takeaway,maps"
+  ["trndheim.no"]="markedsplass,playlist,dating,tv,takeaway,maps"
+  ["stvanger.no"]="markedsplass,playlist,dating,tv,takeaway,maps"
+  ["trmso.no"]="markedsplass,playlist,dating,tv,takeaway,maps"
+  ["longyearbyn.no"]="markedsplass,playlist,dating,tv,takeaway,maps"
+  ["reykjavk.is"]="markadur,playlist,dating,tv,takeaway,maps"
+  ["kobenhvn.dk"]="markedsplads,playlist,dating,tv,takeaway,maps"
+  ["stholm.se"]="marknadsplats,playlist,dating,tv,takeaway,maps"
+  ["gteborg.se"]="marknadsplats,playlist,dating,tv,takeaway,maps"
+  ["mlmoe.se"]="marknadsplats,playlist,dating,tv,takeaway,maps"
+  ["hlsinki.fi"]="markkinapaikka,playlist,dating,tv,takeaway,maps"
+  ["lndon.uk"]="marketplace,playlist,dating,tv,takeaway,maps"
+  ["mnchester.uk"]="marketplace,playlist,dating,tv,takeaway,maps"
+  ["brmingham.uk"]="marketplace,playlist,dating,tv,takeaway,maps"
+  ["edinbrgh.uk"]="marketplace,playlist,dating,tv,takeaway,maps"
+  ["glasgw.uk"]="marketplace,playlist,dating,tv,takeaway,maps"
+  ["lverpool.uk"]="marketplace,playlist,dating,tv,takeaway,maps"
+  ["amstrdam.nl"]="marktplaats,playlist,dating,tv,takeaway,maps"
+  ["rottrdam.nl"]="marktplaats,playlist,dating,tv,takeaway,maps"
+  ["utrcht.nl"]="marktplaats,playlist,dating,tv,takeaway,maps"
+  ["brssels.be"]="marche,playlist,dating,tv,takeaway,maps"
+  ["zrich.ch"]="marktplatz,playlist,dating,tv,takeaway,maps"
+  ["lchtenstein.li"]="marktplatz,playlist,dating,tv,takeaway,maps"
+  ["frankfrt.de"]="marktplatz,playlist,dating,tv,takeaway,maps"
+  ["mrseille.fr"]="marche,playlist,dating,tv,takeaway,maps"
+  ["mlan.it"]="mercato,playlist,dating,tv,takeaway,maps"
+  ["lsbon.pt"]="mercado,playlist,dating,tv,takeaway,maps"
+  ["lsangeles.com"]="marketplace,playlist,dating,tv,takeaway,maps"
+  ["newyrk.us"]="marketplace,playlist,dating,tv,takeaway,maps"
+  ["chcago.us"]="marketplace,playlist,dating,tv,takeaway,maps"
+  ["dtroit.us"]="marketplace,playlist,dating,tv,takeaway,maps"
+  ["houstn.us"]="marketplace,playlist,dating,tv,takeaway,maps"
+  ["dllas.us"]="marketplace,playlist,dating,tv,takeaway,maps"
+  ["austn.us"]="marketplace,playlist,dating,tv,takeaway,maps"
+  ["prtland.com"]="marketplace,playlist,dating,tv,takeaway,maps"
+  ["mnneapolis.com"]="marketplace,playlist,dating,tv,takeaway,maps"
   ["pub.healthcare"]=""
   ["pub.attorney"]=""
-  ["freehelp.legal"]=""
   ["bsdports.org"]=""
-  ["discordb.org"]=""
-  ["foodielicio.us"]=""
-  ["neurotica.fashion"]=""
 )
 
-# Generate Unique Ports for Apps
+# Apps and their primary domains
+typeset -A apps_domains=(
+  ["brgen"]="brgen.no"
+  ["bsdports"]="bsdports.org"
+)
+
+# Generate a unique port for Rails apps
 used_ports=()
 generate_unique_port() {
   while true; do
-    local port=$((2000 + RANDOM % 63000))
-    if [[ ! "${used_ports[@]}" =~ "$port" ]]; then
-      used_ports+="$port"
+    local port=$((40000 + RANDOM % 10000))
+    if [[ ! " ${used_ports[@]} " =~ " $port " ]]; then
+      used_ports+=("$port")
       echo "$port"
       return
     fi
   done
 }
 
-# --
-
-configure_pf() {
-  echo "Configuring pf.conf..."
-  cat > /etc/pf.conf <<EOF
+# Configure PF (packet filter) for firewall rules
+setup_pf() {
+  log "Configuring pf.conf..."
+  cat > /etc/pf.conf << EOF
 ext_if = "vio0"
 
+# Skip filtering on loopback interfaces
 set skip on lo
 
+# Table to track brute force attempts
+table <bruteforce> persist
+
+# Return RSTs instead of silently dropping
+set block-policy return
+
+# Enable logging on external interface
+set loginterface \$ext_if
+
+# Normalize all incoming traffic
+scrub in all
+
+# Block all traffic by default
 block log all
+
+# Allow outgoing traffic
 pass out quick on \$ext_if all
 
-# Allow SSH, HTTP, and HTTPS
+# Allow incoming SSH, HTTP, and HTTPS traffic
 pass in on \$ext_if proto tcp to \$ext_if port { 22, 80, 443 } keep state
 
-# Allow DNS
+# Allow incoming DNS traffic (TCP and UDP)
 pass in on \$ext_if proto { tcp, udp } to \$ext_if port 53 keep state
+
+# Allow ICMP traffic (ping, etc.)
+pass inet proto icmp all icmp-type { echoreq, unreach, timex, paramprob }
+
+# Allow application-specific ports
 EOF
+
+  for app in "${(@k)apps_domains}"; do
+    local app_port=$(generate_unique_port)
+    echo "pass in on \$ext_if proto tcp to \$ext_if port $app_port keep state" >> /etc/pf.conf
+  done
+
   pfctl -f /etc/pf.conf
-  echo "pf.conf configured successfully."
+  log "pf.conf configured and loaded."
 }
 
-# --
+# Configure relayd for reverse proxying Rails apps
+setup_relayd() {
+  log "Configuring relayd.conf..."
+  cat > /etc/relayd.conf << EOF
+egress="$main_ip"
+
+# Protocol for HTTPS relay
+http protocol "secure_rails" {
+  # Set original client IP address
+  match request header set "X-Forwarded-For" value "\$REMOTE_ADDR"
+
+  # Enforce HTTPS communication
+  match response header set "Strict-Transport-Security" value "max-age=31536000; includeSubDomains; preload"
 
-configure_nsd() {
-  echo "Configuring NSD..."
+  # Content Security Policy
+  match response header set "Content-Security-Policy" value "default-src https:; style-src 'self' 'unsafe-inline'; script-src 'self' 'unsafe-inline'; object-src 'none';"
 
-  cd /var/nsd/zones/master
+  # Prevent MIME-type sniffing
+  match response header set "X-Content-Type-Options" value "nosniff"
+
+  # Frame embedding restriction
+  match response header set "X-Frame-Options" value "DENY"
+
+  # Referrer policy
+  match response header set "Referrer-Policy" value "strict-origin"
+
+  forward to <rails_app>
+}
+
+relay "https_relay" {
+  listen on \$egress port 443 tls
+  protocol "secure_rails"
+}
+EOF
+
+  relayctl check
+  rcctl enable relayd
+  rcctl start relayd
+  log "relayd.conf configured and relayd started."
+}
+
+# Configure NSD (name server daemon) for DNS
+setup_nsd() {
+  log "Configuring NSD..."
+  mkdir -p /var/nsd/zones/master /var/nsd/etc
 
-  # Generate DNSSEC keys and zone files
   for domain in "${(@k)all_domains}"; do
     serial=$(date +"%Y%m%d%H")
+    subdomains=$(echo "${all_domains[$domain]}" | sed 's/,/ /g')
 
-    echo "Creating zone file for $domain..."
-    cat > "$domain.zone" <<EOD
+    cat > /var/nsd/zones/master/$domain.zone << EOF
 \$ORIGIN $domain.
-\$TTL 86400
-
+\$TTL 24h
 @ IN SOA ns.brgen.no. admin.$domain. ($serial 1h 15m 1w 3m)
-
 @ IN NS ns.brgen.no.
 @ IN NS ns.hyp.net.
 
 @ IN A $main_ip
 
-@ IN CNAME www
-
-@ IN CAA 0 issue "letsencrypt.org"
-EOD
+ns.brgen.no. IN A $main_ip
+EOF
 
-    # Generate DNSSEC keys
-    ldns-keygen -a RSASHA256 -b 2048 "$domain" > /dev/null
-    sleep 2
+    # Add subdomains as CNAME entries
+    for subdomain in $subdomains; do
+      echo "$subdomain IN CNAME @" >> /var/nsd/zones/master/$domain.zone
+    done
   done
 
-  # NSD main config
-  echo "Creating NSD config file..."
-  cat > /var/nsd/etc/nsd.conf <<EOF
+  # Create NSD configuration
+  cat > /var/nsd/etc/nsd.conf << EOF
 server:
   hide-version: yes
   zonesdir: "/var/nsd/zones/master"
 EOF
 
-  # Enable and start NSD
-  zap -f nsd
+  # Add zones to NSD configuration
+  for domain in "${(@k)all_domains}"; do
+    echo "zone:" >> /var/nsd/etc/nsd.conf
+    echo "  name: \"$domain\"" >> /var/nsd/etc/nsd.conf
+    echo "  zonefile: \"$domain.zone\"" >> /var/nsd/etc/nsd.conf
+  done
 
+  nsd-checkconf
   rcctl enable nsd
-  rcctl start nsd
-  echo "NSD configured and running..."
+  rcctl restart nsd
+  log "NSD configured and started."
 }
 
-# --
+# Configure ACME for SSL certificate management
+setup_acme_httpd() {
+  log "Configuring ACME and HTTPD..."
+  mkdir -p /var/www/acme
+
+  # Base ACME configuration
+  cat > /etc/acme-client.conf << EOF
+authority letsencrypt {
+  api url "https://acme-v02.api.letsencrypt.org/directory"
+}
+EOF
 
-configure_httpd_and_acme_client() {
-  echo "Configuring HTTPD and ACME Client..."
+  # Add domain-specific configurations
+  for domain in "${(@k)all_domains}"; do
+    subdomains=$(echo "${all_domains[$domain]}" | sed 's/,/ /g')
+    cat >> /etc/acme-client.conf << EOF
+domain $domain {
+  alternative name { $subdomains }
+  domain key "/etc/ssl/private/$domain.key"
+  domain fullchain "/etc/ssl/acme/$domain.fullchain"
+  sign with letsencrypt
+}
+EOF
+  done
 
-  echo "Creating HTTPD config file..."
-  cat > /etc/httpd.conf <<EOF
+  # Configure HTTPD for ACME challenges
+  cat > /etc/httpd.conf << EOF
 server "default" {
   listen on * port 80
-  root "/var/www/acme"
   location "/.well-known/acme-challenge/*" {
+    root "/var/www/acme"
     request strip 2
   }
 }
 EOF
-  echo "Creating ACME Client config file..."
-  cat > /etc/acme-client.conf <<EOF
-authority letsencrypt {
-  api url "https://acme-v02.api.letsencrypt.org/directory"
-  account key "/etc/acme/letsencrypt-privkey.pem"
-}
-EOF
-  for domain in "${(@k)all_domains}"; do
-    echo "Configuring ACME Client for $domain..."
-    echo "domain $domain {" >> /etc/acme-client.conf
-    echo "  domain key \"/etc/ssl/private/$domain.key\"" >> /etc/acme-client.conf
-    echo "  domain fullchain \"/etc/ssl/$domain.fullchain.pem\"" >> /etc/acme-client.conf
-    echo "  sign with letsencrypt" >> /etc/acme-client.conf
-    echo "}" >> /etc/acme-client.conf
-  done
-  rcctl enable httpd
-  rcctl enable acme-client
 
+  rcctl enable httpd
   rcctl restart httpd
-  rcctl restart acme-client
-  echo "HTTPD and ACME Client configured and restarted."
+  log "ACME and HTTPD configured and started."
 }
 
-# Configure relayd for HTTPS
-configure_relayd() {
-  echo "Configuring relayd.conf..."
-
-  cat > /etc/relayd.conf <<EOF
-http protocol "http-headers" {
-  # Enforces HTTPS with strict transport security
-  match request header set "Strict-Transport-Security" value "max-age=31536000; includeSubDomains; preload"
-
-  # Defines the content security policy to prevent malicious scripts
-  match request header set "Content-Security-Policy" value "default-src 'self';"
-
-  # Prevents MIME type sniffing
-  match request header set "X-Content-Type-Options" value "nosniff"
-
-  # Protects against clickjacking
-  match request header set "X-Frame-Options" value "SAMEORIGIN"
-
-  # Sets strict referrer policies
-  match request header set "Referrer-Policy" value "strict-origin-when-cross-origin"
-
-  # Limits browser features based on permissions
-  match request header set "Permissions-Policy" value "geolocation=()"
-}
-
-relay "default" {
-  listen on $main_ip port 443 tls
-  protocol "http-headers"
-}
-EOF
-  rcctl enable relayd
-  rcctl restart relayd
-  echo "Relayd configured and restarted."
-}
-
-# --
-
-# https://cvsweb.openbsd.org/cgi-bin/cvsweb/ports/infrastructure/templates/rc.template
-create_startup_scripts() {
-  echo "Creating startup scripts for apps..."
-  for app in "${(@k)all_domains}"; do
+# Create Rails startup scripts
+setup_startup_scripts() {
+  log "Creating Rails app startup scripts..."
+  for app in "${(@k)apps_domains}"; do
     local port=$(generate_unique_port)
-    cat > /etc/rc.d/$app <<EOF
+    cat > /etc/rc.d/$app << EOF
 #!/bin/ksh
 
-. /etc/rc.d/rc.subr
+daemon="/home/$app/bin/rails server"
+daemon_user="$app"
+daemon_flags="-p $port -e production"
 
-name="$app"
-
-rc_start() {
-  /usr/bin/pledge "stdio rpath wpath cpath inet dns proc exec"
-
-  # Restricts operations to essential functionality
-  /usr/bin/unveil "/home/$app" "rwc"
-
-  # Enables access to the application's directory
-  /usr/bin/unveil "/tmp" "rwc"
-
-  # Allows temporary files
-  /usr/bin/unveil -
-
-  # Finalizes unveil restrictions
-  /home/$app/bin/rails server -b 127.0.0.1 -p $port -e production
-}
+. /etc/rc.d/rc.subr
 
-rc_stop() {
-  pkill -f "/home/$app/bin/rails server -b 127.0.0.1 -p $port"
-}
-load_rc_config $name
-run_rc_command "$1"
+rc_cmd \$1
 EOF
     chmod +x /etc/rc.d/$app
+    rcctl enable $app
+    rcctl start $app
+    log "Startup script for $app created and service started."
   done
-  echo "Startup scripts created."
 }
 
-# Execute configurations
-configure_pf
-configure_nsd
-configure_httpd_and_acme_client
-configure_relayd
-create_startup_scripts
+# Main setup function
+main() {
+  log "Starting full OpenBSD server setup..."
+  setup_pf
+  setup_relayd
+  setup_nsd
+  setup_acme_httpd
+  setup_startup_scripts
+  log "OpenBSD server setup complete!"
+}
 
-echo "OpenBSD server setup completed!"
+main
 

commit ca1c0e737caadd49100d1d738f212f3e0460c36f
Author: dev <dev@dev.openbsd.amsterdam>
Date:   Sun Jan 19 16:44:12 2025 +0100

    TMP

diff --git a/README.md b/README.md
index 5ac0250..dc50434 100644
--- a/README.md
+++ b/README.md
@@ -1,78 +1,47 @@
 # OpenBSD Server Automation
-
 **Choose [OpenBSD](https://openbsd.org) for your Unix needs.**  
 OpenBSD is the world’s simplest and most secure Unix-like operating system. It’s a safe alternative to the frequent vulnerabilities and overengineering found in the Linux ecosystem.
-
 ## What This Does
-
 - **Multi-Domain Rails Support**: A set of domains and subdomains pre-configured for your apps.
 - **NSD DNS Server**: Full DNSSEC setup with zone files and keys.
 - **HTTPD & ACME Client**: Automatically configures SSL for your domains.
 - **Relayd Reverse Proxy**: Handles all your traffic routing, including security headers.
 - **Automatic App Startup Scripts**: Ensures your apps are always running on unique ports.
-
 ## Requirements
-
 - OpenBSD 7.x or later
 - Root (or `doas`) access
-
 ## Quick Start
-
 1. **Clone the repository**: 
    ```sh
    git clone https://github.com/your-repo/openbsd-rails-setup.git
    cd openbsd-rails-setup
    ```
-
 2. **Run the script**: 
    ```sh
    doas ./openbsd.sh
    ```
-
 3. **Check your domains**: Visit each domain via the browser, and voila!
-
 ---
-
 ## Key Features
-
 ### Multi-Domain Support
-
 You’ve got a ton of domains with various subdomains? We’ve got you covered! This script auto-generates the necessary Rails application ports, DNS settings, and configuration.
-
 ### DNSSEC with NSD
-
 NSD is set up with full DNSSEC for your domains. Each domain gets its own zone file and DNSSEC keys. Zero manual configuration needed!
-
 ### SSL Certificates with ACME Client
-
 Let’s Encrypt is your new best friend. ACME Client auto-generates and configures certificates for your domains. Say goodbye to manual cert renewals.
-
 ### Relayd for Secure Traffic Routing
-
 Relayd sets up HTTP strict transport security headers, Content Security Policy, and more to protect your apps.
-
 ### Automatic App Start Scripts
-
 For each domain, a unique startup script is created and added to `rc.d`. Apps are served with unique ports and locked down for maximum security.
-
 ---
-
 ## Customization
-
 - **Domains & Subdomains**: You can easily add or modify your domains in the script under `all_domains`. Each domain automatically gets pre-configured zone files.
 - **Port Generation**: Ports for Rails apps are auto-generated and unique for each domain.
 - **Security Headers**: Modify `relayd.conf` to adjust or add headers as per your needs.
-
 ---
-
 ## Troubleshooting
-
 - **NSD not starting?**: Check `/var/log/messages` for error logs. Ensure NSD is properly installed and the zones are correctly set.
 - **SSL issues?**: Verify your ACME configuration and check for errors in `/var/log/acme-client.log`.
-
 ---
-
 ## License
-
 MIT License. OpenBSD Rails Setup is free software and comes with no warranty. Use it at your own risk!
-
diff --git a/openbsd.sh b/openbsd.sh
index b7245c7..c86034f 100644
--- a/openbsd.sh
+++ b/openbsd.sh
@@ -1,6 +1,6 @@
 #!/usr/bin/env zsh
 
-set -e # Exit on error
+set -euo pipefail
 
 echo "Setting up OpenBSD for Rails Apps with Multi-Domain Support"
 
@@ -61,8 +61,8 @@ used_ports=()
 generate_unique_port() {
   while true; do
     local port=$((2000 + RANDOM % 63000))
-    if [[ ! " ${used_ports[@]} " =~ " $port " ]]; then
-      used_ports+=("$port")
+    if [[ ! "${used_ports[@]}" =~ "$port" ]]; then
+      used_ports+="$port"
       echo "$port"
       return
     fi
@@ -86,14 +86,9 @@ pass in on \$ext_if proto tcp to \$ext_if port { 22, 80, 443 } keep state
 
 # Allow DNS
 pass in on \$ext_if proto { tcp, udp } to \$ext_if port 53 keep state
-
-# Ruby on Rails
-anchor "relayd/*"
-
-# Attack prevention
-anchor "sshguard/*"
 EOF
   pfctl -f /etc/pf.conf
+  echo "pf.conf configured successfully."
 }
 
 # --
@@ -103,18 +98,18 @@ configure_nsd() {
 
   cd /var/nsd/zones/master
 
-  # Generate DNSSEC keys and zone files for each domain
+  # Generate DNSSEC keys and zone files
   for domain in "${(@k)all_domains}"; do
     serial=$(date +"%Y%m%d%H")
 
-    # Generate Zone File
+    echo "Creating zone file for $domain..."
     cat > "$domain.zone" <<EOD
 \$ORIGIN $domain.
 \$TTL 86400
 
-@ IN SOA ns.$domain. admin.$domain. ($serial 1h 15m 1w 3m)
+@ IN SOA ns.brgen.no. admin.$domain. ($serial 1h 15m 1w 3m)
 
-@ IN NS ns.$domain.
+@ IN NS ns.brgen.no.
 @ IN NS ns.hyp.net.
 
 @ IN A $main_ip
@@ -122,14 +117,7 @@ configure_nsd() {
 @ IN CNAME www
 
 @ IN CAA 0 issue "letsencrypt.org"
-
-# Subdomains
-EOF
-
-    # Loop through subdomains and add A records
-    for subdomain in ${(s/ /)all_domains[$domain]}; do
-      echo "$subdomain IN A $main_ip" >> "$domain.zone"
-    done
+EOD
 
     # Generate DNSSEC keys
     ldns-keygen -a RSASHA256 -b 2048 "$domain" > /dev/null
@@ -137,6 +125,7 @@ EOF
   done
 
   # NSD main config
+  echo "Creating NSD config file..."
   cat > /var/nsd/etc/nsd.conf <<EOF
 server:
   hide-version: yes
@@ -144,6 +133,8 @@ server:
 EOF
 
   # Enable and start NSD
+  zap -f nsd
+
   rcctl enable nsd
   rcctl start nsd
   echo "NSD configured and running..."
@@ -154,6 +145,7 @@ EOF
 configure_httpd_and_acme_client() {
   echo "Configuring HTTPD and ACME Client..."
 
+  echo "Creating HTTPD config file..."
   cat > /etc/httpd.conf <<EOF
 server "default" {
   listen on * port 80
@@ -163,33 +155,30 @@ server "default" {
   }
 }
 EOF
-
-  # Generate ACME Client configuration for Let's Encrypt
+  echo "Creating ACME Client config file..."
   cat > /etc/acme-client.conf <<EOF
 authority letsencrypt {
   api url "https://acme-v02.api.letsencrypt.org/directory"
   account key "/etc/acme/letsencrypt-privkey.pem"
 }
 EOF
-
-  # Loop through all domains and add ACME client configuration
   for domain in "${(@k)all_domains}"; do
+    echo "Configuring ACME Client for $domain..."
     echo "domain $domain {" >> /etc/acme-client.conf
     echo "  domain key \"/etc/ssl/private/$domain.key\"" >> /etc/acme-client.conf
     echo "  domain fullchain \"/etc/ssl/$domain.fullchain.pem\"" >> /etc/acme-client.conf
     echo "  sign with letsencrypt" >> /etc/acme-client.conf
     echo "}" >> /etc/acme-client.conf
   done
-
-  # Enable and restart services
   rcctl enable httpd
   rcctl enable acme-client
+
   rcctl restart httpd
   rcctl restart acme-client
+  echo "HTTPD and ACME Client configured and restarted."
 }
 
-# --
-
+# Configure relayd for HTTPS
 configure_relayd() {
   echo "Configuring relayd.conf..."
 
@@ -219,14 +208,16 @@ relay "default" {
   protocol "http-headers"
 }
 EOF
-
   rcctl enable relayd
   rcctl restart relayd
+  echo "Relayd configured and restarted."
 }
 
 # --
 
+# https://cvsweb.openbsd.org/cgi-bin/cvsweb/ports/infrastructure/templates/rc.template
 create_startup_scripts() {
+  echo "Creating startup scripts for apps..."
   for app in "${(@k)all_domains}"; do
     local port=$(generate_unique_port)
     cat > /etc/rc.d/$app <<EOF
@@ -259,19 +250,16 @@ load_rc_config $name
 run_rc_command "$1"
 EOF
     chmod +x /etc/rc.d/$app
-    rcctl enable $app
   done
+  echo "Startup scripts created."
 }
 
-# Main Execution
-echo "Starting setup..."
-
-# Run configuration phases
+# Execute configurations
 configure_pf
 configure_nsd
 configure_httpd_and_acme_client
 configure_relayd
 create_startup_scripts
 
-echo "Setup completed successfully."
+echo "OpenBSD server setup completed!"
 

commit d0217e78877b913809d844165bfaa41c6214339a
Author: dev <dev@dev.openbsd.amsterdam>
Date:   Sat Jan 11 18:11:20 2025 +0100

    TMP

diff --git a/README.md b/README.md
index b02ea42..5ac0250 100644
--- a/README.md
+++ b/README.md
@@ -1,79 +1,78 @@
-# OpenBSD Rails Server Setup
+# OpenBSD Server Automation
 
-## Overview
+**Choose [OpenBSD](https://openbsd.org) for your Unix needs.**  
+OpenBSD is the world’s simplest and most secure Unix-like operating system. It’s a safe alternative to the frequent vulnerabilities and overengineering found in the Linux ecosystem.
 
-This setup script automates the deployment of an OpenBSD VPS as a secure, optimized hosting environment for Ruby on Rails applications. It handles essential installations, security configurations, domain management, and SSL certification, creating a production-ready server setup.
+## What This Does
 
-## Features
+- **Multi-Domain Rails Support**: A set of domains and subdomains pre-configured for your apps.
+- **NSD DNS Server**: Full DNSSEC setup with zone files and keys.
+- **HTTPD & ACME Client**: Automatically configures SSL for your domains.
+- **Relayd Reverse Proxy**: Handles all your traffic routing, including security headers.
+- **Automatic App Startup Scripts**: Ensures your apps are always running on unique ports.
 
-- **Automated Software Installation**: Installs necessary components, including `ruby`, `postgresql-server`, `redis`, `varnish`, `monit`, and `sshguard` for security and monitoring.
-- **Dynamic Port Management**: Prevents port conflicts through automated port assignment using a random port generator.
-- **Firewall Configuration (`pf.conf(5)` and `pfctl(8)`)**: Configures OpenBSD’s Packet Filter to secure the server by controlling access and limiting vulnerabilities.
-- **Traffic Routing with `relayd(8)`**: Configures `relayd` as a reverse proxy to manage HTTP/HTTPS traffic, directing it securely to Rails applications.
-- **DNS Management with `nsd(8)`**: Uses `nsd` to configure DNS zones for each domain and subdomain, with DNSSEC enabled for added security.
-- **SSL Automation with `acme-client(8)`**: Uses `acme-client` with Let’s Encrypt for automated SSL certificate issuance and renewal.
-- **Rails Application Management (`rc.d(8)` scripts)**: Generates startup scripts for each Rails application, enabling seamless control through `rcctl(8)`.
+## Requirements
 
-## Configuration Details
+- OpenBSD 7.x or later
+- Root (or `doas`) access
 
-### Domains and Subdomains
+## Quick Start
 
-The script supports multiple domains and subdomains, specified in the `ALL_DOMAINS` list. Each domain configuration includes DNS records, SSL certificates, and `relayd` routing rules.
+1. **Clone the repository**: 
+   ```sh
+   git clone https://github.com/your-repo/openbsd-rails-setup.git
+   cd openbsd-rails-setup
+   ```
 
-### Port Management
+2. **Run the script**: 
+   ```sh
+   doas ./openbsd.sh
+   ```
 
-The `generate_random_port()` function assigns available ports dynamically to avoid conflicts across services such as `relayd` and Rails applications.
+3. **Check your domains**: Visit each domain via the browser, and voila!
 
-### SSL Certificates and Secure Connections
+---
 
-Using `acme-client(8)` with Let’s Encrypt, the script automatically handles SSL certificate issuance and renewal for all domains, ensuring secure HTTPS connections. OpenBSD’s `httpd(8)` is configured to respond to ACME challenges, automating the SSL setup.
+## Key Features
 
-### Firewall Configuration with `pf.conf(5)` and `pfctl(8)`
+### Multi-Domain Support
 
-The firewall (`pf`) is configured to control inbound and outbound traffic, enhancing server security. It includes brute-force protection for SSH using `sshguard`, rate-limiting, and access controls for DNS, HTTP, and HTTPS, ensuring only authorized access.
+You’ve got a ton of domains with various subdomains? We’ve got you covered! This script auto-generates the necessary Rails application ports, DNS settings, and configuration.
 
-### Traffic Management with `relayd(8)` and `relayd.conf(5)`
+### DNSSEC with NSD
 
-`relayd` directs HTTP and HTTPS traffic with two specific protocols:
+NSD is set up with full DNSSEC for your domains. Each domain gets its own zone file and DNSSEC keys. Zero manual configuration needed!
 
-- **ACME Challenge Routing**: Routes SSL certificate validation requests to `acme-client`.
-- **Application Request Routing**: Forwards user traffic to the Rails applications via Varnish, enhancing scalability and security.
+### SSL Certificates with ACME Client
 
-### DNS Management with `nsd(8)` and `nsd.conf(5)`
+Let’s Encrypt is your new best friend. ACME Client auto-generates and configures certificates for your domains. Say goodbye to manual cert renewals.
 
-The `configure_nsd` function automates DNS zone configuration for each domain, enabling DNSSEC to ensure integrity and authenticity of DNS records.
+### Relayd for Secure Traffic Routing
 
-### Rails Application Startup and Management with `rc.d(8)` and `rcctl(8)`
+Relayd sets up HTTP strict transport security headers, Content Security Policy, and more to protect your apps.
 
-Each Rails application is configured with a startup script in `/etc/rc.d/`. These scripts allow `rcctl` to manage application start and stop processes, using Falcon as the application server. Security measures like `unveil` and `pledge` are used to restrict system calls and file system access.
+### Automatic App Start Scripts
 
-## Usage Instructions
+For each domain, a unique startup script is created and added to `rc.d`. Apps are served with unique ports and locked down for maximum security.
 
-1. **Prepare the Server**: Ensure you have a fresh OpenBSD installation with `doas` configured for your user.
+---
 
-2. **Copy the Script**: Place the `openbsd.sh` script on your server.
+## Customization
 
-3. **Make the Script Executable**:
+- **Domains & Subdomains**: You can easily add or modify your domains in the script under `all_domains`. Each domain automatically gets pre-configured zone files.
+- **Port Generation**: Ports for Rails apps are auto-generated and unique for each domain.
+- **Security Headers**: Modify `relayd.conf` to adjust or add headers as per your needs.
 
-    ```sh
-    chmod +x openbsd.sh
-    ```
+---
 
-4. **Run the Script**:
+## Troubleshooting
 
-    ```sh
-    ./openbsd.sh
-    ```
+- **NSD not starting?**: Check `/var/log/messages` for error logs. Ensure NSD is properly installed and the zones are correctly set.
+- **SSL issues?**: Verify your ACME configuration and check for errors in `/var/log/acme-client.log`.
 
-5. **Deploy Your Rails Applications**: Place your Rails applications in `/home/<app_name>/<app_name>`, where `<app_name>` corresponds to each name in `RAILS_APPS`.
+---
 
-## Notes
+## License
 
-- **Ensure Domain Ownership**: Before running the script, make sure you own or control all the domains listed in `ALL_DOMAINS`.
-- **DNS Configuration**: You may need to set up glue records or adjust your registrar's settings to point to your NSD server.
-- **Review the Script**: It's good practice to review and understand the script before running it, especially since it makes significant changes to your system configuration.
-
-## Acknowledgments
-
-This script leverages OpenBSD's robust features to provide a secure and efficient environment for hosting Rails applications. Special thanks to the OpenBSD community for their excellent documentation and tools.
+MIT License. OpenBSD Rails Setup is free software and comes with no warranty. Use it at your own risk!
 
diff --git a/openbsd.sh b/openbsd.sh
index 7bb32c9..b7245c7 100644
--- a/openbsd.sh
+++ b/openbsd.sh
@@ -1,366 +1,277 @@
 #!/usr/bin/env zsh
-set -e
-
-# OpenBSD VPS setup for Ruby on Rails
-
-OPENBSD_AMSTERDAM_IP="46.23.95.45"
-
-ALL_DOMAINS=(
-  "brgen.no:markedsplass,playlist,dating,tv,takeaway,maps"
-  "oshlo.no:markedsplass,playlist,dating,tv,takeaway,maps"
-  "trndheim.no:markedsplass,playlist,dating,tv,takeaway,maps"
-  "stvanger.no:markedsplass,playlist,dating,tv,takeaway,maps"
-  "trmso.no:markedsplass,playlist,dating,tv,takeaway,maps"
-  "longyearbyn.no:markedsplass,playlist,dating,tv,takeaway,maps"
-  "reykjavk.is:markadur,playlist,dating,tv,takeaway,maps"
-  "kbenhvn.dk:markedsplads,playlist,dating,tv,takeaway,maps"
-  "stholm.se:marknadsplats,playlist,dating,tv,takeaway,maps"
-  "gteborg.se:marknadsplats,playlist,dating,tv,takeaway,maps"
-  "mlmoe.se:marknadsplats,playlist,dating,tv,takeaway,maps"
-  "hlsinki.fi:markkinapaikka,playlist,dating,tv,takeaway,maps"
-  "lndon.uk:marketplace,playlist,dating,tv,takeaway,maps"
-  "mnchester.uk:marketplace,playlist,dating,tv,takeaway,maps"
-  "brmingham.uk:marketplace,playlist,dating,tv,takeaway,maps"
-  "edinbrgh.uk:marketplace,playlist,dating,tv,takeaway,maps"
-  "glasgw.uk:marketplace,playlist,dating,tv,takeaway,maps"
-  "lverpool.uk:marketplace,playlist,dating,tv,takeaway,maps"
-  "amstrdam.nl:marktplaats,playlist,dating,tv,takeaway,maps"
-  "rottrdam.nl:marktplaats,playlist,dating,tv,takeaway,maps"
-  "utrcht.nl:marktplaats,playlist,dating,tv,takeaway,maps"
-  "brussels.be:marche,playlist,dating,tv,takeaway,maps"
-  "zurich.ch:marktplatz,playlist,dating,tv,takeaway,maps"
-  "lichtenstein.li:marktplatz,playlist,dating,tv,takeaway,maps"
-  "frankfurt.de:marktplatz,playlist,dating,tv,takeaway,maps"
-  "marseille.fr:marche,playlist,dating,tv,takeaway,maps"
-  "milan.it:mercato,playlist,dating,tv,takeaway,maps"
-  "lisbon.pt:mercado,playlist,dating,tv,takeaway,maps"
-  "lsangeles.com:marketplace,playlist,dating,tv,takeaway,maps"
-  "newyrk.us:marketplace,playlist,dating,tv,takeaway,maps"
-  "chcago.us:marketplace,playlist,dating,tv,takeaway,maps"
-  "dtroit.us:marketplace,playlist,dating,tv,takeaway,maps"
-  "houstn.us:marketplace,playlist,dating,tv,takeaway,maps"
-  "dllas.us:marketplace,playlist,dating,tv,takeaway,maps"
-  "austn.us:marketplace,playlist,dating,tv,takeaway,maps"
-  "prtland.com:marketplace,playlist,dating,tv,takeaway,maps"
-  "mnneapolis.com:marketplace,playlist,dating,tv,takeaway,maps"
-  "neurotica.fashion"
-  "bsdports.org"
-)
 
-RAILS_APPS=("brgen" "bsdports" "amber")
+set -e # Exit on error
+
+echo "Setting up OpenBSD for Rails Apps with Multi-Domain Support"
+
+# Primary Server IP
+main_ip="46.23.95.45"
+
+# Domains and Subdomains Definitions
+typeset -A all_domains
+all_domains=(
+  ["brgen.no"]="markedsplass playlist dating tv takeaway maps"
+  ["oshlo.no"]="markedsplass playlist dating tv takeaway maps"
+  ["trndheim.no"]="markedsplass playlist dating tv takeaway maps"
+  ["stvanger.no"]="markedsplass playlist dating tv takeaway maps"
+  ["trmso.no"]="markedsplass playlist dating tv takeaway maps"
+  ["longyearbyn.no"]="markedsplass playlist dating tv takeaway maps"
+  ["reykjavk.is"]="markadur playlist dating tv takeaway maps"
+  ["kobenhvn.dk"]="markedsplads playlist dating tv takeaway maps"
+  ["stholm.se"]="marknadsplats playlist dating tv takeaway maps"
+  ["gteborg.se"]="marknadsplats playlist dating tv takeaway maps"
+  ["mlmoe.se"]="marknadsplats playlist dating tv takeaway maps"
+  ["hlsinki.fi"]="markkinapaikka playlist dating tv takeaway maps"
+  ["lndon.uk"]="marketplace playlist dating tv takeaway maps"
+  ["mnchester.uk"]="marketplace playlist dating tv takeaway maps"
+  ["brmingham.uk"]="marketplace playlist dating tv takeaway maps"
+  ["edinbrgh.uk"]="marketplace playlist dating tv takeaway maps"
+  ["glasgw.uk"]="marketplace playlist dating tv takeaway maps"
+  ["lverpool.uk"]="marketplace playlist dating tv takeaway maps"
+  ["amstrdam.nl"]="marktplaats playlist dating tv takeaway maps"
+  ["rottrdam.nl"]="marktplaats playlist dating tv takeaway maps"
+  ["utrcht.nl"]="marktplaats playlist dating tv takeaway maps"
+  ["brssels.be"]="marche playlist dating tv takeaway maps"
+  ["zrich.ch"]="marktplatz playlist dating tv takeaway maps"
+  ["lchtenstein.li"]="marktplatz playlist dating tv takeaway maps"
+  ["frankfrt.de"]="marktplatz playlist dating tv takeaway maps"
+  ["mrseille.fr"]="marche playlist dating tv takeaway maps"
+  ["mlan.it"]="mercato playlist dating tv takeaway maps"
+  ["lsbon.pt"]="mercado playlist dating tv takeaway maps"
+  ["lsangeles.com"]="marketplace playlist dating tv takeaway maps"
+  ["newyrk.us"]="marketplace playlist dating tv takeaway maps"
+  ["chcago.us"]="marketplace playlist dating tv takeaway maps"
+  ["dtroit.us"]="marketplace playlist dating tv takeaway maps"
+  ["houstn.us"]="marketplace playlist dating tv takeaway maps"
+  ["dllas.us"]="marketplace playlist dating tv takeaway maps"
+  ["austn.us"]="marketplace playlist dating tv takeaway maps"
+  ["prtland.com"]="marketplace playlist dating tv takeaway maps"
+  ["mnneapolis.com"]="marketplace playlist dating tv takeaway maps"
+  ["pub.healthcare"]=""
+  ["pub.attorney"]=""
+  ["freehelp.legal"]=""
+  ["bsdports.org"]=""
+  ["discordb.org"]=""
+  ["foodielicio.us"]=""
+  ["neurotica.fashion"]=""
+)
 
-generate_random_port() {
-  echo $((2000 + RANDOM % 63000))
+# Generate Unique Ports for Apps
+used_ports=()
+generate_unique_port() {
+  while true; do
+    local port=$((2000 + RANDOM % 63000))
+    if [[ ! " ${used_ports[@]} " =~ " $port " ]]; then
+      used_ports+=("$port")
+      echo "$port"
+      return
+    fi
+  done
 }
 
-ACME_CLIENT_PORT=$(generate_random_port)
-VARNISH_PORT=$(generate_random_port)
+# --
 
-install_packages() {
-  doas pkg_add -UI ldns-utils ruby-3.3.5 postgresql-server redis varnish monit sshguard
-}
-
-# Function to configure the Packet Filter (pf)
 configure_pf() {
-  doas tee /etc/pf.conf > /dev/null <<EOF
+  echo "Configuring pf.conf..."
+  cat > /etc/pf.conf <<EOF
+ext_if = "vio0"
+
 set skip on lo
-block all
 
-# Allow SSH and protect with sshguard
-pass in quick on egress proto tcp to port 22 keep state
+block log all
+pass out quick on \$ext_if all
 
-# Allow DNS
-pass in on egress proto { tcp, udp } to port 53 keep state
+# Allow SSH, HTTP, and HTTPS
+pass in on \$ext_if proto tcp to \$ext_if port { 22, 80, 443 } keep state
 
-# Allow HTTP/HTTPS
-pass in on egress proto tcp to port { 80, 443 } keep state
+# Allow DNS
+pass in on \$ext_if proto { tcp, udp } to \$ext_if port 53 keep state
 
-# Allow all outgoing traffic
-pass out on egress keep state
+# Ruby on Rails
+anchor "relayd/*"
 
-# SSHGuard
+# Attack prevention
 anchor "sshguard/*"
-
-# Relay rules
-anchor "relayd/*"
 EOF
-
-  doas pfctl -f /etc/pf.conf
-
-  doas rcctl enable sshguard
-  doas rcctl start sshguard
+  pfctl -f /etc/pf.conf
 }
 
+# --
+
 configure_nsd() {
-  doas tee /var/nsd/etc/nsd.conf > /dev/null <<EOF
-server:
-  ip-address: "46.23.95.45"
-  hide-version: yes
-  verbosity: 2
-  zonesdir: "/var/nsd/zones"
-
-remote-control:
-  control-enable: yes
-  control-interface: 127.0.0.1
-  control-port: 8952
-  server-key-file: "/var/nsd/etc/nsd_server.key"
-  server-cert-file: "/var/nsd/etc/nsd_server.pem"
-  control-key-file: "/var/nsd/etc/nsd_control.key"
-  control-cert-file: "/var/nsd/etc/nsd_control.pem"
-
-pattern:
-  name: "default"
-  zonefile: "master/%s.zone"
-  notify: yes
-EOF
+  echo "Configuring NSD..."
 
-  for domain_entry in "${ALL_DOMAINS[@]}"; do
-    # Split domain and subdomains
-    domain="${domain_entry%%:*}"
-    subdomains="${domain_entry#*:}"
-
-    # Generate DNSSEC keys (overwrite any existing keys)
-    echo "Generating keys for $domain..."
-    doas sh -c "cd /var/nsd/zones/master && ldns-keygen -a ECDSAP256SHA256 -b 256 -r /dev/urandom $domain"
-    if [ $? -ne 0 ]; then
-      echo "Error: Key generation for $domain failed."
-      continue
-    fi
+  cd /var/nsd/zones/master
 
-    local serial=$(date +"%Y%m%d%H")
+  # Generate DNSSEC keys and zone files for each domain
+  for domain in "${(@k)all_domains}"; do
+    serial=$(date +"%Y%m%d%H")
 
-    # Create the zone file (overwrite if exists)
-    doas tee /var/nsd/zones/master/$domain.zone > /dev/null <<ZONE
+    # Generate Zone File
+    cat > "$domain.zone" <<EOD
 \$ORIGIN $domain.
-\$TTL 3600
-
-@ IN SOA ns.brgen.no. hostmaster.$domain. (
-  $serial ; Serial
-  3600 ; Refresh
-  900 ; Retry
-  1209600 ; Expire
-  3600 ; Minimum TTL
-)
-@ IN NS ns.brgen.no.
+\$TTL 86400
+
+@ IN SOA ns.$domain. admin.$domain. ($serial 1h 15m 1w 3m)
+
+@ IN NS ns.$domain.
 @ IN NS ns.hyp.net.
 
-ns.brgen.no. IN A $OPENBSD_AMSTERDAM_IP
+@ IN A $main_ip
+
+@ IN CNAME www
 
 @ IN CAA 0 issue "letsencrypt.org"
-ZONE
 
-    if [[ -n "$subdomains" ]]; then
-      local subdomain_array=(${(s/,/)subdomains})
-      for subdomain in "${subdomain_array[@]}"; do
-        echo "$subdomain IN CNAME @" | doas tee -a /var/nsd/zones/master/$domain.zone > /dev/null
-      done
-    fi
+# Subdomains
+EOF
 
-    # Sign the zone file with DNSSEC, using the generated keys
-    echo "Signing the zone for $domain..."
-    doas sh -c "cd /var/nsd/zones/master && ldns-signzone -n -p -o $domain $domain.zone"
-    if [ $? -ne 0 ]; then
-      echo "Error: Zone signing for $domain failed."
-      continue
-    fi
+    # Loop through subdomains and add A records
+    for subdomain in ${(s/ /)all_domains[$domain]}; do
+      echo "$subdomain IN A $main_ip" >> "$domain.zone"
+    done
+
+    # Generate DNSSEC keys
+    ldns-keygen -a RSASHA256 -b 2048 "$domain" > /dev/null
+    sleep 2
   done
 
-  doas rcctl enable nsd
-  doas rcctl restart nsd
+  # NSD main config
+  cat > /var/nsd/etc/nsd.conf <<EOF
+server:
+  hide-version: yes
+  zonesdir: "/var/nsd/zones/master"
+EOF
+
+  # Enable and start NSD
+  rcctl enable nsd
+  rcctl start nsd
+  echo "NSD configured and running..."
 }
 
-# Function to configure httpd and acme-client for SSL certificates
-configure_httpd_and_acme_client() {
-  doas mkdir -p /var/www/acme/.well-known/acme-challenge
-  doas chown -R www:www /var/www/acme
+# --
 
-  if [[ ! -f /etc/acme/letsencrypt-privkey.pem ]]; then
-    doas openssl genpkey -algorithm RSA -out /etc/acme/letsencrypt-privkey.pem -pkeyopt rsa_keygen_bits:2048
-  fi
+configure_httpd_and_acme_client() {
+  echo "Configuring HTTPD and ACME Client..."
 
-  doas tee /etc/httpd.conf > /dev/null <<EOF
-server "acme" {
-  listen on $OPENBSD_AMSTERDAM_IP port $ACME_CLIENT_PORT
+  cat > /etc/httpd.conf <<EOF
+server "default" {
+  listen on * port 80
+  root "/var/www/acme"
   location "/.well-known/acme-challenge/*" {
-    root "/acme"
     request strip 2
   }
 }
 EOF
 
-  doas rcctl enable httpd
-  doas rcctl restart httpd
-
-  doas tee /etc/acme-client.conf > /dev/null <<EOF
+  # Generate ACME Client configuration for Let's Encrypt
+  cat > /etc/acme-client.conf <<EOF
 authority letsencrypt {
   api url "https://acme-v02.api.letsencrypt.org/directory"
   account key "/etc/acme/letsencrypt-privkey.pem"
 }
 EOF
 
-  for domain in "${(k)ALL_DOMAINS}"; do
-    doas tee -a /etc/acme-client.conf > /dev/null <<EOF
-domain $domain {
-  domain key "/etc/ssl/private/$domain.key"
-  domain fullchain "/etc/ssl/$domain.fullchain.pem"
-  sign with letsencrypt
-}
-EOF
+  # Loop through all domains and add ACME client configuration
+  for domain in "${(@k)all_domains}"; do
+    echo "domain $domain {" >> /etc/acme-client.conf
+    echo "  domain key \"/etc/ssl/private/$domain.key\"" >> /etc/acme-client.conf
+    echo "  domain fullchain \"/etc/ssl/$domain.fullchain.pem\"" >> /etc/acme-client.conf
+    echo "  sign with letsencrypt" >> /etc/acme-client.conf
+    echo "}" >> /etc/acme-client.conf
   done
 
-  for domain in "${(k)ALL_DOMAINS}"; do
-    echo "Generating certificate for $domain using ACME client..."
-    doas acme-client -v "$domain"
-  done
+  # Enable and restart services
+  rcctl enable httpd
+  rcctl enable acme-client
+  rcctl restart httpd
+  rcctl restart acme-client
 }
 
-# Function to configure relayd for traffic routing
+# --
+
 configure_relayd() {
-  doas tee /etc/relayd.conf > /dev/null <<EOF
-log connection
+  echo "Configuring relayd.conf..."
 
-table <acme_client> { 127.0.0.1:$ACME_CLIENT_PORT }
+  cat > /etc/relayd.conf <<EOF
+http protocol "http-headers" {
+  # Enforces HTTPS with strict transport security
+  match request header set "Strict-Transport-Security" value "max-age=31536000; includeSubDomains; preload"
 
-http protocol "filter_challenge" {
-  pass request path "/.well-known/acme-challenge/*" forward to <acme_client>
-}
+  # Defines the content security policy to prevent malicious scripts
+  match request header set "Content-Security-Policy" value "default-src 'self';"
 
-http protocol "varnish_backend" {
-  match request header set "X-Forwarded-By" value "\$SERVER_ADDR:\$SERVER_PORT"
-  match request header set "X-Forwarded-For" value "\$REMOTE_ADDR"
-  match response header set "Strict-Transport-Security" value "max-age=31536000; includeSubDomains; preload"
-  match response header set "X-Frame-Options" value "SAMEORIGIN"
-  match response header set "Content-Security-Policy" value "upgrade-insecure-requests"
-  match response header set "X-Content-Type-Options" value "nosniff"
-  match response header set "Referrer-Policy" value "no-referrer"
-  match response header set "Permissions-Policy" value "geolocation=*"
-}
+  # Prevents MIME type sniffing
+  match request header set "X-Content-Type-Options" value "nosniff"
 
-relay "acme_relay" {
-  listen on $OPENBSD_AMSTERDAM_IP port 80
-  protocol "filter_challenge"
-  forward to 127.0.0.1 port $ACME_CLIENT_PORT
+  # Protects against clickjacking
+  match request header set "X-Frame-Options" value "SAMEORIGIN"
+
+  # Sets strict referrer policies
+  match request header set "Referrer-Policy" value "strict-origin-when-cross-origin"
+
+  # Limits browser features based on permissions
+  match request header set "Permissions-Policy" value "geolocation=()"
 }
 
-relay "https_relay" {
-  listen on $OPENBSD_AMSTERDAM_IP port 443 tls
-  protocol "varnish_backend"
-  forward to 127.0.0.1 port $VARNISH_PORT
+relay "default" {
+  listen on $main_ip port 443 tls
+  protocol "http-headers"
 }
 EOF
 
-  doas rcctl enable relayd
-  doas rcctl restart relayd
+  rcctl enable relayd
+  rcctl restart relayd
 }
 
-# Function to configure startup scripts for Rails applications
-configure_startup_scripts() {
-  typeset -A APP_BACKEND_PORTS
-  for app in $RAILS_APPS; do
-    if ! id "$app" >/dev/null 2>&1; then
-      doas useradd -m -s /bin/ksh "$app"
-    fi
-
-    # Generate a unique backend port for the app
-    local backend_port
-    repeat 1; do
-      backend_port=$(generate_random_port)
-      [[ -z "${APP_BACKEND_PORTS[$backend_port]}" ]] && break
-    done
-    APP_BACKEND_PORTS[$app]=$backend_port
+# --
 
-    doas tee "/etc/rc.d/$app" > /dev/null <<EOF
+create_startup_scripts() {
+  for app in "${(@k)all_domains}"; do
+    local port=$(generate_unique_port)
+    cat > /etc/rc.d/$app <<EOF
 #!/bin/ksh
 
-daemon="/bin/ksh -c 'cd /home/$app/$app && export RAILS_ENV=production && /usr/local/bin/bundle exec falcon serve -b tcp://127.0.0.1:$backend_port'"
-daemon_user="$app"
-
-unveil -r /home/$app/$app
-unveil /var/www/log w
-unveil /etc/ssl r
-unveil
-
-pledge stdio rpath wpath cpath inet dns
-
 . /etc/rc.d/rc.subr
-rc_cmd \$1
-EOF
 
-    doas chmod +x "/etc/rc.d/$app"
-    doas rcctl enable "$app"
-    doas rcctl start "$app"
-  done
-}
+name="$app"
 
-# Function to configure Varnish for caching and routing
-configure_varnish() {
-  doas tee /etc/varnish/default.vcl > /dev/null <<EOF
-vcl 4.0;
-EOF
+rc_start() {
+  /usr/bin/pledge "stdio rpath wpath cpath inet dns proc exec"
 
-  # Define backends for each application
-  for app in $RAILS_APPS; do
-    local backend_port="${APP_BACKEND_PORTS[$app]}"
-    doas tee -a /etc/varnish/default.vcl > /dev/null <<EOF
+  # Restricts operations to essential functionality
+  /usr/bin/unveil "/home/$app" "rwc"
 
-backend ${app}_backend {
-  .host = "127.0.0.1";
-  .port = "${backend_port}";
-}
-EOF
-  done
-
-  # Configure request handling
-  doas tee -a /etc/varnish/default.vcl > /dev/null <<'EOF'
-
-sub vcl_recv {
-  if (req.url ~ "^/assets/") {
-    unset req.http.cookie;
-  }
+  # Enables access to the application's directory
+  /usr/bin/unveil "/tmp" "rwc"
 
-  if (req.http.host) {
-    set req.backend_hint = default;
+  # Allows temporary files
+  /usr/bin/unveil -
 
-EOF
-
-  for domain in "${(k)ALL_DOMAINS}"; do
-    local app="${domain%%.*}"
-    if [[ " $RAILS_APPS " == *" $app "* ]]; then
-      doas tee -a /etc/varnish/default.vcl > /dev/null <<EOF
-    if (req.http.host == "$domain") {
-      set req.backend_hint = ${app}_backend;
-    }
-EOF
-    fi
-  done
-
-  # Close the sub vcl_recv
-  doas tee -a /etc/varnish/default.vcl > /dev/null <<'EOF'
-  }
+  # Finalizes unveil restrictions
+  /home/$app/bin/rails server -b 127.0.0.1 -p $port -e production
 }
 
-sub vcl_backend_response {
-  if (beresp.status == 200) {
-    set beresp.ttl = 1h;
-  }
+rc_stop() {
+  pkill -f "/home/$app/bin/rails server -b 127.0.0.1 -p $port"
 }
+load_rc_config $name
+run_rc_command "$1"
 EOF
-
-  doas rcctl enable varnishd
-  doas rcctl set varnishd flags "-a :$VARNISH_PORT -f /etc/varnish/default.vcl -s malloc,256m"
-  doas rcctl restart varnishd
+    chmod +x /etc/rc.d/$app
+    rcctl enable $app
+  done
 }
 
-# Main function to execute all setup steps
-main() {
-  install_packages
-  configure_pf
-  configure_nsd
-  configure_httpd_and_acme_client
-  configure_startup_scripts
-  configure_relayd
-  configure_varnish
-}
+# Main Execution
+echo "Starting setup..."
+
+# Run configuration phases
+configure_pf
+configure_nsd
+configure_httpd_and_acme_client
+configure_relayd
+create_startup_scripts
 
-main "$@"
+echo "Setup completed successfully."
 

commit d3eae469bbce975ebbe23faa17abed20390dcef1
Author: dev <dev@dev.openbsd.amsterdam>
Date:   Mon Dec 9 00:10:43 2024 +0100

    TMP

diff --git a/README.md b/README.md
index aa7979e..b02ea42 100644
--- a/README.md
+++ b/README.md
@@ -6,8 +6,8 @@ This setup script automates the deployment of an OpenBSD VPS as a secure, optimi
 
 ## Features
 
-- **Automated Software Installation**: Installs necessary components, including `ruby`, `postgresql-server`, `redis`, and `varnish` for web acceleration.
-- **Dynamic Port Management**: Prevents port conflicts through automated port assignment.
+- **Automated Software Installation**: Installs necessary components, including `ruby`, `postgresql-server`, `redis`, `varnish`, `monit`, and `sshguard` for security and monitoring.
+- **Dynamic Port Management**: Prevents port conflicts through automated port assignment using a random port generator.
 - **Firewall Configuration (`pf.conf(5)` and `pfctl(8)`)**: Configures OpenBSD’s Packet Filter to secure the server by controlling access and limiting vulnerabilities.
 - **Traffic Routing with `relayd(8)`**: Configures `relayd` as a reverse proxy to manage HTTP/HTTPS traffic, directing it securely to Rails applications.
 - **DNS Management with `nsd(8)`**: Uses `nsd` to configure DNS zones for each domain and subdomain, with DNSSEC enabled for added security.
@@ -30,13 +30,14 @@ Using `acme-client(8)` with Let’s Encrypt, the script automatically handles SS
 
 ### Firewall Configuration with `pf.conf(5)` and `pfctl(8)`
 
-The firewall (`pf`) is configured to control inbound and outbound traffic, enhancing server security. It includes brute-force protection for SSH, rate-limiting, and access controls for DNS, HTTP, and HTTPS, ensuring only authorized access.
+The firewall (`pf`) is configured to control inbound and outbound traffic, enhancing server security. It includes brute-force protection for SSH using `sshguard`, rate-limiting, and access controls for DNS, HTTP, and HTTPS, ensuring only authorized access.
 
 ### Traffic Management with `relayd(8)` and `relayd.conf(5)`
 
 `relayd` directs HTTP and HTTPS traffic with two specific protocols:
+
 - **ACME Challenge Routing**: Routes SSL certificate validation requests to `acme-client`.
-- **Application Request Routing**: Forwards user traffic to the Rails applications, enhancing scalability and security.
+- **Application Request Routing**: Forwards user traffic to the Rails applications via Varnish, enhancing scalability and security.
 
 ### DNS Management with `nsd(8)` and `nsd.conf(5)`
 
@@ -44,5 +45,35 @@ The `configure_nsd` function automates DNS zone configuration for each domain, e
 
 ### Rails Application Startup and Management with `rc.d(8)` and `rcctl(8)`
 
-Each Rails application is configured with a startup script in `/etc/rc.d/`. These scripts allow `rcctl` to manage application start and stop processes, using Falcon as the application server.
+Each Rails application is configured with a startup script in `/etc/rc.d/`. These scripts allow `rcctl` to manage application start and stop processes, using Falcon as the application server. Security measures like `unveil` and `pledge` are used to restrict system calls and file system access.
+
+## Usage Instructions
+
+1. **Prepare the Server**: Ensure you have a fresh OpenBSD installation with `doas` configured for your user.
+
+2. **Copy the Script**: Place the `openbsd.sh` script on your server.
+
+3. **Make the Script Executable**:
+
+    ```sh
+    chmod +x openbsd.sh
+    ```
+
+4. **Run the Script**:
+
+    ```sh
+    ./openbsd.sh
+    ```
+
+5. **Deploy Your Rails Applications**: Place your Rails applications in `/home/<app_name>/<app_name>`, where `<app_name>` corresponds to each name in `RAILS_APPS`.
+
+## Notes
+
+- **Ensure Domain Ownership**: Before running the script, make sure you own or control all the domains listed in `ALL_DOMAINS`.
+- **DNS Configuration**: You may need to set up glue records or adjust your registrar's settings to point to your NSD server.
+- **Review the Script**: It's good practice to review and understand the script before running it, especially since it makes significant changes to your system configuration.
+
+## Acknowledgments
+
+This script leverages OpenBSD's robust features to provide a secure and efficient environment for hosting Rails applications. Special thanks to the OpenBSD community for their excellent documentation and tools.
 
diff --git a/openbsd.sh b/openbsd.sh
index 18d7a33..7bb32c9 100644
--- a/openbsd.sh
+++ b/openbsd.sh
@@ -1,6 +1,7 @@
 #!/usr/bin/env zsh
 set -e
-setopt nullglob
+
+# OpenBSD VPS setup for Ruby on Rails
 
 OPENBSD_AMSTERDAM_IP="46.23.95.45"
 
@@ -46,79 +47,90 @@ ALL_DOMAINS=(
   "bsdports.org"
 )
 
-RAILS_APPS=("brgen" "amber" "bsdports")
-
-install_packages() {
-  local packages=("ldns-utils" "ruby-3.3.5" "postgresql-server" "redis" "varnish" "monit" "sshguard")
-
-  for package in "${packages[@]}"; do
-    doas pkg_add -UI "$package"
-  done
-}
+RAILS_APPS=("brgen" "bsdports" "amber")
 
 generate_random_port() {
   echo $((2000 + RANDOM % 63000))
 }
 
+ACME_CLIENT_PORT=$(generate_random_port)
+VARNISH_PORT=$(generate_random_port)
+
+install_packages() {
+  doas pkg_add -UI ldns-utils ruby-3.3.5 postgresql-server redis varnish monit sshguard
+}
+
+# Function to configure the Packet Filter (pf)
 configure_pf() {
-  cat <<EOF | doas tee /etc/pf.conf > /dev/null
+  doas tee /etc/pf.conf > /dev/null <<EOF
 set skip on lo
 block all
 
-# Allow SSH
-pass in on vio0 proto tcp to port 22 keep state
+# Allow SSH and protect with sshguard
+pass in quick on egress proto tcp to port 22 keep state
 
 # Allow DNS
-pass in on vio0 proto { tcp, udp } from any to port 53 keep state
+pass in on egress proto { tcp, udp } to port 53 keep state
 
 # Allow HTTP/HTTPS
-pass in on vio0 proto tcp to port { 80, 443 } keep state
+pass in on egress proto tcp to port { 80, 443 } keep state
 
 # Allow all outgoing traffic
-pass out on vio0 keep state
+pass out on egress keep state
+
+# SSHGuard
+anchor "sshguard/*"
 
 # Relay rules
 anchor "relayd/*"
 EOF
 
   doas pfctl -f /etc/pf.conf
+
+  doas rcctl enable sshguard
+  doas rcctl start sshguard
 }
 
 configure_nsd() {
-  echo "Setting up NSD..."
-
-  # Create required directories if they do not exist
-  doas mkdir -p /var/nsd/zones/master /etc/nsd
-
-  # Write the main NSD configuration
-  cat <<EOF | doas tee /etc/nsd/nsd.conf > /dev/null
+  doas tee /var/nsd/etc/nsd.conf > /dev/null <<EOF
 server:
-  ip-address: $OPENBSD_AMSTERDAM_IP
+  ip-address: "46.23.95.45"
   hide-version: yes
-  ip4-only: yes
-  zonesdir: "/var/nsd/zones/master"
-  logfile: "/var/log/nsd.log"
+  verbosity: 2
+  zonesdir: "/var/nsd/zones"
+
+remote-control:
+  control-enable: yes
+  control-interface: 127.0.0.1
+  control-port: 8952
+  server-key-file: "/var/nsd/etc/nsd_server.key"
+  server-cert-file: "/var/nsd/etc/nsd_server.pem"
+  control-key-file: "/var/nsd/etc/nsd_control.key"
+  control-cert-file: "/var/nsd/etc/nsd_control.pem"
+
+pattern:
+  name: "default"
+  zonefile: "master/%s.zone"
+  notify: yes
 EOF
 
-  # Loop through all domains and configure zones
-  for domain_info in "${ALL_DOMAINS[@]}"; do
-    local domain="${domain_info%%:*}"
-    [[ -z "$domain" ]] && continue
-
-    echo "Configuring zone for $domain..."
-
-    # Check if DNSSEC keys exist
-    local key_exists=$(find /var/nsd/zones/master -name "K${domain}.+*.key" | wc -l)
-    if [[ $key_exists -eq 0 ]]; then
-      doas sh -c "cd /var/nsd/zones/master && ldns-keygen -a ECDSAP256SHA256 -b 256 -r /dev/urandom $domain"
+  for domain_entry in "${ALL_DOMAINS[@]}"; do
+    # Split domain and subdomains
+    domain="${domain_entry%%:*}"
+    subdomains="${domain_entry#*:}"
+
+    # Generate DNSSEC keys (overwrite any existing keys)
+    echo "Generating keys for $domain..."
+    doas sh -c "cd /var/nsd/zones/master && ldns-keygen -a ECDSAP256SHA256 -b 256 -r /dev/urandom $domain"
+    if [ $? -ne 0 ]; then
+      echo "Error: Key generation for $domain failed."
+      continue
     fi
 
-    # Define the zone's serial number based on the current date and time
     local serial=$(date +"%Y%m%d%H")
 
-    # Create the zone file if it doesn't exist
-    if [[ ! -f "/var/nsd/zones/master/${domain}.zone" ]]; then
-      cat <<ZONE | doas tee /var/nsd/zones/master/$domain.zone > /dev/null
+    # Create the zone file (overwrite if exists)
+    doas tee /var/nsd/zones/master/$domain.zone > /dev/null <<ZONE
 \$ORIGIN $domain.
 \$TTL 3600
 
@@ -131,71 +143,63 @@ EOF
 )
 @ IN NS ns.brgen.no.
 @ IN NS ns.hyp.net.
+
 ns.brgen.no. IN A $OPENBSD_AMSTERDAM_IP
+
 @ IN CAA 0 issue "letsencrypt.org"
 ZONE
 
-      # Optionally add CNAME records for subdomains if defined in domain_info
-      local subdomains=$(echo "$domain_info" | cut -d ':' -f 2)
-      if [[ -n "$subdomains" ]]; then
-        IFS=',' read -r -a subdomain_array <<< "$subdomains"
-        for subdomain in "${subdomain_array[@]}"; do
-          echo "$subdomain IN CNAME @" | doas tee -a "/var/nsd/zones/master/$domain.zone" > /dev/null
-        done
-      fi
+    if [[ -n "$subdomains" ]]; then
+      local subdomain_array=(${(s/,/)subdomains})
+      for subdomain in "${subdomain_array[@]}"; do
+        echo "$subdomain IN CNAME @" | doas tee -a /var/nsd/zones/master/$domain.zone > /dev/null
+      done
     fi
 
-    # Sign the zone file with DNSSEC if not already signed
-    if [[ ! -f "/var/nsd/zones/master/${domain}.zone.signed" ]]; then
-      doas ldns-signzone -n -p -o "$domain" "/var/nsd/zones/master/$domain.zone"
+    # Sign the zone file with DNSSEC, using the generated keys
+    echo "Signing the zone for $domain..."
+    doas sh -c "cd /var/nsd/zones/master && ldns-signzone -n -p -o $domain $domain.zone"
+    if [ $? -ne 0 ]; then
+      echo "Error: Zone signing for $domain failed."
+      continue
     fi
   done
 
-  # Restart NSD to apply the configuration
-  echo "Enabling and starting NSD..."
   doas rcctl enable nsd
   doas rcctl restart nsd
 }
 
+# Function to configure httpd and acme-client for SSL certificates
 configure_httpd_and_acme_client() {
-  # Generate a private key for Let's Encrypt if it doesn't exist
+  doas mkdir -p /var/www/acme/.well-known/acme-challenge
+  doas chown -R www:www /var/www/acme
+
   if [[ ! -f /etc/acme/letsencrypt-privkey.pem ]]; then
     doas openssl genpkey -algorithm RSA -out /etc/acme/letsencrypt-privkey.pem -pkeyopt rsa_keygen_bits:2048
   fi
 
-  # Configure httpd to serve ACME challenge responses
-  cat <<EOF | doas tee /etc/httpd.conf > /dev/null
+  doas tee /etc/httpd.conf > /dev/null <<EOF
 server "acme" {
-  listen on $OPENBSD_AMSTERDAM_IP port 80
+  listen on $OPENBSD_AMSTERDAM_IP port $ACME_CLIENT_PORT
   location "/.well-known/acme-challenge/*" {
-    root "/var/www/acme"
+    root "/acme"
     request strip 2
   }
 }
 EOF
 
-  # Restart the httpd service to apply changes
+  doas rcctl enable httpd
   doas rcctl restart httpd
 
-  # Set up the ACME client configuration file for Let's Encrypt
-  cat <<EOF | doas tee /etc/acme-client.conf > /dev/null
+  doas tee /etc/acme-client.conf > /dev/null <<EOF
 authority letsencrypt {
   api url "https://acme-v02.api.letsencrypt.org/directory"
   account key "/etc/acme/letsencrypt-privkey.pem"
 }
 EOF
 
-  # Loop through all domains to configure ACME client for each
-  > /tmp/acme-client.conf.tmp # Initialize a new file to avoid concatenation errors
-  for domain_info in "${ALL_DOMAINS[@]}"; do
-    # Extract the primary domain from the string (before colon)
-    local domain="${domain_info%%:*}"
-
-    # If domain is empty, skip to the next one
-    [[ -z "$domain" ]] && continue
-
-    # Append the domain's ACME configuration
-    cat <<EOF >> /tmp/acme-client.conf.tmp
+  for domain in "${(k)ALL_DOMAINS}"; do
+    doas tee -a /etc/acme-client.conf > /dev/null <<EOF
 domain $domain {
   domain key "/etc/ssl/private/$domain.key"
   domain fullchain "/etc/ssl/$domain.fullchain.pem"
@@ -204,39 +208,23 @@ domain $domain {
 EOF
   done
 
-  # Move the final ACME client configuration to the correct location
-  doas mv /tmp/acme-client.conf.tmp /etc/acme-client.conf
-
-  # Generate certificates for each domain if not already present
-  for domain_info in "${ALL_DOMAINS[@]}"; do
-    local domain="${domain_info%%:*}"
-    [[ -z "$domain" ]] && continue
-
-    if [[ ! -f "/etc/ssl/$domain.fullchain.pem" ]]; then
-      echo "Generating certificate for $domain using ACME client..."
-      doas acme-client -v "$domain"
-    else
-      echo "Certificate for $domain already exists, skipping ACME request."
-    fi
+  for domain in "${(k)ALL_DOMAINS}"; do
+    echo "Generating certificate for $domain using ACME client..."
+    doas acme-client -v "$domain"
   done
 }
 
+# Function to configure relayd for traffic routing
 configure_relayd() {
-  local acme_client_port=$(generate_random_port)
-  local varnish_port=$(generate_random_port)
-
-  cat <<EOF | doas tee /etc/relayd.conf > /dev/null
+  doas tee /etc/relayd.conf > /dev/null <<EOF
 log connection
 
-# Define a table for routing ACME client challenges to localhost
-table <acme_client> { 127.0.0.1:$acme_client_port }
+table <acme_client> { 127.0.0.1:$ACME_CLIENT_PORT }
 
-# HTTP protocol for ACME challenges
 http protocol "filter_challenge" {
   pass request path "/.well-known/acme-challenge/*" forward to <acme_client>
 }
 
-# HTTP protocol for backend Varnish server
 http protocol "varnish_backend" {
   match request header set "X-Forwarded-By" value "\$SERVER_ADDR:\$SERVER_PORT"
   match request header set "X-Forwarded-For" value "\$REMOTE_ADDR"
@@ -250,68 +238,49 @@ http protocol "varnish_backend" {
 
 relay "acme_relay" {
   listen on $OPENBSD_AMSTERDAM_IP port 80
-  forward to 127.0.0.1 port $acme_client_port protocol "filter_challenge"
+  protocol "filter_challenge"
+  forward to 127.0.0.1 port $ACME_CLIENT_PORT
 }
 
 relay "https_relay" {
   listen on $OPENBSD_AMSTERDAM_IP port 443 tls
   protocol "varnish_backend"
-  forward to 127.0.0.1 port $varnish_port
+  forward to 127.0.0.1 port $VARNISH_PORT
 }
 EOF
 
+  doas rcctl enable relayd
   doas rcctl restart relayd
 }
 
-configure_varnish() {
-  local varnish_port=$(generate_random_port)
-  local falcon_backend_port=$(generate_random_port)
-
-  cat <<EOF | doas tee /etc/varnish/default.vcl > /dev/null
-vcl 4.0;
-
-backend default {
-  .host = "127.0.0.1";
-  .port = "$falcon_backend_port";
-}
-
-sub vcl_recv {
-  if (req.url ~ "^/assets/") {
-    unset req.http.cookie;
-  }
-}
-
-sub vcl_backend_response {
-  if (beresp.status == 200) {
-    set beresp.ttl = 1h;
-  }
-}
-EOF
-
-  doas rcctl set varnishd flags "-a :$varnish_port -b localhost:$falcon_backend_port"
-  doas rcctl start varnishd
-}
-
+# Function to configure startup scripts for Rails applications
 configure_startup_scripts() {
-  for app in "${RAILS_APPS[@]}"; do
-    if ! doas grep -q "^$app:" /etc/master.passwd; then
+  typeset -A APP_BACKEND_PORTS
+  for app in $RAILS_APPS; do
+    if ! id "$app" >/dev/null 2>&1; then
       doas useradd -m -s /bin/ksh "$app"
     fi
 
-    local backend_port=$(generate_random_port)
+    # Generate a unique backend port for the app
+    local backend_port
+    repeat 1; do
+      backend_port=$(generate_random_port)
+      [[ -z "${APP_BACKEND_PORTS[$backend_port]}" ]] && break
+    done
+    APP_BACKEND_PORTS[$app]=$backend_port
 
-    cat <<EOF | doas tee "/etc/rc.d/$app" > /dev/null
+    doas tee "/etc/rc.d/$app" > /dev/null <<EOF
 #!/bin/ksh
 
 daemon="/bin/ksh -c 'cd /home/$app/$app && export RAILS_ENV=production && /usr/local/bin/bundle exec falcon serve -b tcp://127.0.0.1:$backend_port'"
 daemon_user="$app"
 
 unveil -r /home/$app/$app
-unveil /var/www/log
-unveil /etc/ssl
+unveil /var/www/log w
+unveil /etc/ssl r
 unveil
 
-pledge stdio rpath wpath cpath inet
+pledge stdio rpath wpath cpath inet dns
 
 . /etc/rc.d/rc.subr
 rc_cmd \$1
@@ -323,14 +292,74 @@ EOF
   done
 }
 
+# Function to configure Varnish for caching and routing
+configure_varnish() {
+  doas tee /etc/varnish/default.vcl > /dev/null <<EOF
+vcl 4.0;
+EOF
+
+  # Define backends for each application
+  for app in $RAILS_APPS; do
+    local backend_port="${APP_BACKEND_PORTS[$app]}"
+    doas tee -a /etc/varnish/default.vcl > /dev/null <<EOF
+
+backend ${app}_backend {
+  .host = "127.0.0.1";
+  .port = "${backend_port}";
+}
+EOF
+  done
+
+  # Configure request handling
+  doas tee -a /etc/varnish/default.vcl > /dev/null <<'EOF'
+
+sub vcl_recv {
+  if (req.url ~ "^/assets/") {
+    unset req.http.cookie;
+  }
+
+  if (req.http.host) {
+    set req.backend_hint = default;
+
+EOF
+
+  for domain in "${(k)ALL_DOMAINS}"; do
+    local app="${domain%%.*}"
+    if [[ " $RAILS_APPS " == *" $app "* ]]; then
+      doas tee -a /etc/varnish/default.vcl > /dev/null <<EOF
+    if (req.http.host == "$domain") {
+      set req.backend_hint = ${app}_backend;
+    }
+EOF
+    fi
+  done
+
+  # Close the sub vcl_recv
+  doas tee -a /etc/varnish/default.vcl > /dev/null <<'EOF'
+  }
+}
+
+sub vcl_backend_response {
+  if (beresp.status == 200) {
+    set beresp.ttl = 1h;
+  }
+}
+EOF
+
+  doas rcctl enable varnishd
+  doas rcctl set varnishd flags "-a :$VARNISH_PORT -f /etc/varnish/default.vcl -s malloc,256m"
+  doas rcctl restart varnishd
+}
+
+# Main function to execute all setup steps
 main() {
   install_packages
   configure_pf
   configure_nsd
   configure_httpd_and_acme_client
+  configure_startup_scripts
   configure_relayd
   configure_varnish
-  configure_startup_scripts
 }
 
 main "$@"

commit 468f97d31c7df2563d8df6a6154bcd73fb067cdf
Author: dev <dev@dev.openbsd.amsterdam>
Date:   Fri Nov 22 21:46:11 2024 +0100

    TMP

diff --git a/README.md b/README.md
index a9a7228..aa7979e 100644
--- a/README.md
+++ b/README.md
@@ -1,95 +1,48 @@
-# __openbsd.sh Setup Script
+# OpenBSD Rails Server Setup
 
 ## Overview
 
-This script automates the setup of an OpenBSD environment configured for Ruby on Rails development. It includes the installation of required packages, configuration of firewall rules using Packet Filter (pf), relayd setup for reverse proxying, and NSD setup for DNS management.
+This setup script automates the deployment of an OpenBSD VPS as a secure, optimized hosting environment for Ruby on Rails applications. It handles essential installations, security configurations, domain management, and SSL certification, creating a production-ready server setup.
 
 ## Features
 
-- **Automatic Package Installation**: Installs required packages such as Ruby, PostgreSQL, Redis, and others.
-- **Dynamic Domain Loading**: Loads domains from an external configuration file for easy management and maintainability.
-- **Firewall Configuration (pf)**: Configures OpenBSD's Packet Filter to enhance security, including brute-force attack protection and trusted IP handling for SSH.
-- **Reverse Proxy Configuration (relayd)**: Sets up relayd for HTTP traffic to support load balancing and forwarding.
-- **DNS Configuration (NSD)**: Automates the creation of zone files for managing DNS entries across various domains and subdomains.
+- **Automated Software Installation**: Installs necessary components, including `ruby`, `postgresql-server`, `redis`, and `varnish` for web acceleration.
+- **Dynamic Port Management**: Prevents port conflicts through automated port assignment.
+- **Firewall Configuration (`pf.conf(5)` and `pfctl(8)`)**: Configures OpenBSD’s Packet Filter to secure the server by controlling access and limiting vulnerabilities.
+- **Traffic Routing with `relayd(8)`**: Configures `relayd` as a reverse proxy to manage HTTP/HTTPS traffic, directing it securely to Rails applications.
+- **DNS Management with `nsd(8)`**: Uses `nsd` to configure DNS zones for each domain and subdomain, with DNSSEC enabled for added security.
+- **SSL Automation with `acme-client(8)`**: Uses `acme-client` with Let’s Encrypt for automated SSL certificate issuance and renewal.
+- **Rails Application Management (`rc.d(8)` scripts)**: Generates startup scripts for each Rails application, enabling seamless control through `rcctl(8)`.
 
-## Prerequisites
+## Configuration Details
 
-- OpenBSD system with `doas` configured.
-- Configuration file `/etc/openbsd_domains.conf` with the domains and subdomains to be managed.
-- Internet access for package installation.
+### Domains and Subdomains
 
-## Usage
+The script supports multiple domains and subdomains, specified in the `ALL_DOMAINS` list. Each domain configuration includes DNS records, SSL certificates, and `relayd` routing rules.
 
-### Running the Script
+### Port Management
 
-To execute the script, run the following command:
+The `generate_random_port()` function assigns available ports dynamically to avoid conflicts across services such as `relayd` and Rails applications.
 
-    ./__openbsd.sh
+### SSL Certificates and Secure Connections
 
-Ensure the script has executable permissions:
+Using `acme-client(8)` with Let’s Encrypt, the script automatically handles SSL certificate issuance and renewal for all domains, ensuring secure HTTPS connections. OpenBSD’s `httpd(8)` is configured to respond to ACME challenges, automating the SSL setup.
 
-    chmod +x __openbsd.sh
+### Firewall Configuration with `pf.conf(5)` and `pfctl(8)`
 
-### Configuration File
+The firewall (`pf`) is configured to control inbound and outbound traffic, enhancing server security. It includes brute-force protection for SSH, rate-limiting, and access controls for DNS, HTTP, and HTTPS, ensuring only authorized access.
 
-The domains to be managed are loaded from `/etc/openbsd_domains.conf`. This file should contain the domain definitions in the format expected by the script, allowing for easy updates without modifying the script itself.
+### Traffic Management with `relayd(8)` and `relayd.conf(5)`
 
-## Detailed Steps
+`relayd` directs HTTP and HTTPS traffic with two specific protocols:
+- **ACME Challenge Routing**: Routes SSL certificate validation requests to `acme-client`.
+- **Application Request Routing**: Forwards user traffic to the Rails applications, enhancing scalability and security.
 
-### 1. Package Installation
+### DNS Management with `nsd(8)` and `nsd.conf(5)`
 
-The script installs several necessary packages:
+The `configure_nsd` function automates DNS zone configuration for each domain, enabling DNSSEC to ensure integrity and authenticity of DNS records.
 
-- `ruby`: Ruby programming language.
-- `postgresql-server`: Database server for Rails.
-- `dnscrypt-proxy`: DNS security.
-- `redis`: In-memory data store.
-- `varnish`: HTTP reverse proxy.
+### Rails Application Startup and Management with `rc.d(8)` and `rcctl(8)`
 
-The latest version of each package is determined and installed using OpenBSD's `pkg_add` tool.
+Each Rails application is configured with a startup script in `/etc/rc.d/`. These scripts allow `rcctl` to manage application start and stop processes, using Falcon as the application server.
 
-### 2. Packet Filter (pf) Configuration
-
-- Configures `pf` to block unwanted incoming traffic by default.
-- Protects against brute-force attacks by rate-limiting SSH connections and blocking offending IPs.
-- Allows incoming connections for HTTP, HTTPS, DNS, and SSH (from trusted IPs).
-- Loads the configuration from a temporary file and applies it.
-
-### 3. Relayd Configuration
-
-- Configures `relayd` for HTTP traffic management.
-- Sets up a backend table for local services (`127.0.0.1`) and listens for incoming HTTP requests on port 80.
-- Copies the generated configuration to `/etc/relayd.conf`.
-
-### 4. NSD (Name Server Daemon) Configuration
-
-- Sets up zone files for each domain listed in `/etc/openbsd_domains.conf`.
-- Configures SOA, NS, and A records for the domains and their respective subdomains.
-- Utilizes a timestamp as the serial number for SOA records to ensure DNS changes are properly propagated.
-
-## Logs
-
-- All log messages generated by the script are written to `/var/log/openbsd_setup.log` for auditing and troubleshooting purposes.
-
-## Error Handling
-
-- The script includes retry mechanisms for package installation and configuration steps to handle transient issues.
-- If any critical step fails after multiple attempts, the script will exit and log the failure.
-
-## Notes
-
-- Ensure that the `/etc/openbsd_domains.conf` file is properly formatted and contains the correct domain information before running the script.
-- This script is intended for environments where `doas` is used instead of `sudo`.
-
-## Example `/etc/openbsd_domains.conf` Format
-
-    typeset -A all_domains=(
-      ["example.com"]=("www" "blog" "shop")
-      ["anotherdomain.com"]=("api" "app" "static")
-    )
-
-This format allows you to specify the main domains and their respective subdomains, which the script will use to generate the appropriate DNS zone files.
-
-## Disclaimer
-
-This script is provided as-is and should be tested in a development environment before using it in production. Make sure to adjust configurations to match your specific use case and security requirements.
diff --git a/openbsd.sh b/openbsd.sh
index 245296a..18d7a33 100644
--- a/openbsd.sh
+++ b/openbsd.sh
@@ -1,347 +1,337 @@
 #!/usr/bin/env zsh
+set -e
+setopt nullglob
+
+OPENBSD_AMSTERDAM_IP="46.23.95.45"
+
+ALL_DOMAINS=(
+  "brgen.no:markedsplass,playlist,dating,tv,takeaway,maps"
+  "oshlo.no:markedsplass,playlist,dating,tv,takeaway,maps"
+  "trndheim.no:markedsplass,playlist,dating,tv,takeaway,maps"
+  "stvanger.no:markedsplass,playlist,dating,tv,takeaway,maps"
+  "trmso.no:markedsplass,playlist,dating,tv,takeaway,maps"
+  "longyearbyn.no:markedsplass,playlist,dating,tv,takeaway,maps"
+  "reykjavk.is:markadur,playlist,dating,tv,takeaway,maps"
+  "kbenhvn.dk:markedsplads,playlist,dating,tv,takeaway,maps"
+  "stholm.se:marknadsplats,playlist,dating,tv,takeaway,maps"
+  "gteborg.se:marknadsplats,playlist,dating,tv,takeaway,maps"
+  "mlmoe.se:marknadsplats,playlist,dating,tv,takeaway,maps"
+  "hlsinki.fi:markkinapaikka,playlist,dating,tv,takeaway,maps"
+  "lndon.uk:marketplace,playlist,dating,tv,takeaway,maps"
+  "mnchester.uk:marketplace,playlist,dating,tv,takeaway,maps"
+  "brmingham.uk:marketplace,playlist,dating,tv,takeaway,maps"
+  "edinbrgh.uk:marketplace,playlist,dating,tv,takeaway,maps"
+  "glasgw.uk:marketplace,playlist,dating,tv,takeaway,maps"
+  "lverpool.uk:marketplace,playlist,dating,tv,takeaway,maps"
+  "amstrdam.nl:marktplaats,playlist,dating,tv,takeaway,maps"
+  "rottrdam.nl:marktplaats,playlist,dating,tv,takeaway,maps"
+  "utrcht.nl:marktplaats,playlist,dating,tv,takeaway,maps"
+  "brussels.be:marche,playlist,dating,tv,takeaway,maps"
+  "zurich.ch:marktplatz,playlist,dating,tv,takeaway,maps"
+  "lichtenstein.li:marktplatz,playlist,dating,tv,takeaway,maps"
+  "frankfurt.de:marktplatz,playlist,dating,tv,takeaway,maps"
+  "marseille.fr:marche,playlist,dating,tv,takeaway,maps"
+  "milan.it:mercato,playlist,dating,tv,takeaway,maps"
+  "lisbon.pt:mercado,playlist,dating,tv,takeaway,maps"
+  "lsangeles.com:marketplace,playlist,dating,tv,takeaway,maps"
+  "newyrk.us:marketplace,playlist,dating,tv,takeaway,maps"
+  "chcago.us:marketplace,playlist,dating,tv,takeaway,maps"
+  "dtroit.us:marketplace,playlist,dating,tv,takeaway,maps"
+  "houstn.us:marketplace,playlist,dating,tv,takeaway,maps"
+  "dllas.us:marketplace,playlist,dating,tv,takeaway,maps"
+  "austn.us:marketplace,playlist,dating,tv,takeaway,maps"
+  "prtland.com:marketplace,playlist,dating,tv,takeaway,maps"
+  "mnneapolis.com:marketplace,playlist,dating,tv,takeaway,maps"
+  "neurotica.fashion"
+  "bsdports.org"
+)
 
-openbsd_amsterdam="46.23.95.45"
-log_file="/var/log/openbsd_setup.log"
-hyp_net="194.63.248.53"
-ext_if="vio0"
+RAILS_APPS=("brgen" "amber" "bsdports")
 
-# Initial setup and logging
-echo "Configuring OpenBSD for Ruby on Rails..." | tee -a $log_file
+install_packages() {
+  local packages=("ldns-utils" "ruby-3.3.5" "postgresql-server" "redis" "varnish" "monit" "sshguard")
 
-# Function to generate a random port within a safe range and avoid port collisions
-generate_random_port() {
-  local port
-  port=$((RANDOM % 64511 + 1024))
-  while sockstat -l | grep -q ":$port"; do
-    port=$((RANDOM % 64511 + 1024))
+  for package in "${packages[@]}"; do
+    doas pkg_add -UI "$package"
   done
-  echo $port
 }
 
-# Define domains and apps
-# This map assigns each domain to its respective apps and will be used later to configure services
-typeset -A all_domains=(
-  ["brgen.no"]="markedsplass playlist dating tv takeaway maps"
-  ["oshlo.no"]="markedsplass playlist dating tv takeaway maps"
-  ["trndheim.no"]="markedsplass playlist dating tv takeaway maps"
-  ["stvanger.no"]="markedsplass playlist dating tv takeaway maps"
-  ["trmso.no"]="markedsplass playlist dating tv takeaway maps"
-  ["longyearbyn.no"]="markedsplass playlist dating tv takeaway maps"
-  ["reykjavk.is"]="markadur playlist dating tv takeaway maps"
-  ["kobenhvn.dk"]="markedsplads playlist dating tv takeaway maps"
-  ["stholm.se"]="marknadsplats playlist dating tv takeaway maps"
-  ["gteborg.se"]="marknadsplats playlist dating tv takeaway maps"
-  ["mlmoe.se"]="marknadsplats playlist dating tv takeaway maps"
-  ["hlsinki.fi"]="markkinapaikka playlist dating tv takeaway maps"
-  ["lndon.uk"]="marketplace playlist dating tv takeaway maps"
-  ["mnchester.uk"]="marketplace playlist dating tv takeaway maps"
-  ["brmingham.uk"]="marketplace playlist dating tv takeaway maps"
-  ["edinbrgh.uk"]="marketplace playlist dating tv takeaway maps"
-  ["glasgw.uk"]="marketplace playlist dating tv takeaway maps"
-  ["lverpool.uk"]="marketplace playlist dating tv takeaway maps"
-  ["amstrdam.nl"]="marktplaats playlist dating tv takeaway maps"
-  ["rottrdam.nl"]="marktplaats playlist dating tv takeaway maps"
-  ["utrcht.nl"]="marktplaats playlist dating tv takeaway maps"
-  ["brssels.be"]="marche playlist dating tv takeaway maps"
-  ["zrich.ch"]="marktplatz playlist dating tv takeaway maps"
-  ["lchtenstein.li"]="marktplatz playlist dating tv takeaway maps"
-  ["frankfrt.de"]="marktplatz playlist dating tv takeaway maps"
-  ["mrseille.fr"]="marche playlist dating tv takeaway maps"
-  ["mlan.it"]="mercato playlist dating tv takeaway maps"
-  ["lsbon.pt"]="mercado playlist dating tv takeaway maps"
-  ["lsangeles.com"]="marketplace playlist dating tv takeaway maps"
-)
+generate_random_port() {
+  echo $((2000 + RANDOM % 63000))
+}
 
-# Allocate dynamic ports for each app under each domain
-typeset -A apps_domains
-for domain in ${(k)all_domains}; do
-  for app in ${(s: :)all_domains[$domain]}; do
-    apps_domains["$app-$domain"]="127.0.0.1:$(generate_random_port)"
-  done
-done
-
-# -- INSTALLATION BEGIN --
-# Install necessary packages: Ruby, PostgreSQL, Redis, Varnish, DNS, and security tools
-echo "Installing necessary packages..." | tee -a $log_file
-retry_command() {
-  local retries=3
-  local delay=5
-  local count=0
-  while (( count < retries )); do
-    if "$@"; then
-      return 0
-    else
-      ((count++))
-      echo "Retrying in $delay seconds..." | tee -a $log_file
-      sleep $delay
-    fi
-  done
-  return 1
+configure_pf() {
+  cat <<EOF | doas tee /etc/pf.conf > /dev/null
+set skip on lo
+block all
+
+# Allow SSH
+pass in on vio0 proto tcp to port 22 keep state
+
+# Allow DNS
+pass in on vio0 proto { tcp, udp } from any to port 53 keep state
+
+# Allow HTTP/HTTPS
+pass in on vio0 proto tcp to port { 80, 443 } keep state
+
+# Allow all outgoing traffic
+pass out on vio0 keep state
+
+# Relay rules
+anchor "relayd/*"
+EOF
+
+  doas pfctl -f /etc/pf.conf
 }
 
-if ! retry_command doas pkg_add -UI ruby postgresql-server dnscrypt-proxy sshguard monit redis varnish; then
-  echo "Package installation failed. Exiting." | tee -a $log_file
-  exit 1
-fi
-echo "Packages installed successfully." | tee -a $log_file
+configure_nsd() {
+  echo "Setting up NSD..."
 
-# PF (Packet Filter) Configuration
-# This configures the OpenBSD firewall, blocking unwanted traffic and allowing only essential services like SSH, HTTP, HTTPS, and DNS
-echo "Configuring pf(4)..." | tee -a $log_file
-doas tee /etc/pf.conf > /dev/null << EOF
-ext_if = "$ext_if"
+  # Create required directories if they do not exist
+  doas mkdir -p /var/nsd/zones/master /etc/nsd
 
-set skip on lo  # Skip loopback interface
-block return  # Block all traffic by default
-pass  # Allow traffic based on subsequent rules
+  # Write the main NSD configuration
+  cat <<EOF | doas tee /etc/nsd/nsd.conf > /dev/null
+server:
+  ip-address: $OPENBSD_AMSTERDAM_IP
+  hide-version: yes
+  ip4-only: yes
+  zonesdir: "/var/nsd/zones/master"
+  logfile: "/var/log/nsd.log"
+EOF
 
-# Brute-force protection: Blocks IPs that exceed connection limits on SSH
-table <bruteforce> persist
-block quick from <bruteforce>
+  # Loop through all domains and configure zones
+  for domain_info in "${ALL_DOMAINS[@]}"; do
+    local domain="${domain_info%%:*}"
+    [[ -z "$domain" ]] && continue
 
-# Allow SSH with relaxed rate-limiting to prevent accidental lockout
-pass in on \$ext_if inet proto tcp from any to \$ext_if port 22 keep state (max-src-conn 50, max-src-conn-rate 20/60, overload <bruteforce> flush global)
+    echo "Configuring zone for $domain..."
 
-# Allow DNS (both TCP and UDP)
-pass in on \$ext_if inet proto { tcp, udp } from any to \$ext_if port 53 keep state
+    # Check if DNSSEC keys exist
+    local key_exists=$(find /var/nsd/zones/master -name "K${domain}.+*.key" | wc -l)
+    if [[ $key_exists -eq 0 ]]; then
+      doas sh -c "cd /var/nsd/zones/master && ldns-keygen -a ECDSAP256SHA256 -b 256 -r /dev/urandom $domain"
+    fi
 
-# Allow HTTP and HTTPS traffic
-pass in on \$ext_if inet proto tcp from any to \$ext_if port { 80, 443 } keep state
+    # Define the zone's serial number based on the current date and time
+    local serial=$(date +"%Y%m%d%H")
 
-# Enable packet scrubbing (fragment reassembly)
-scrub in on \$ext_if all fragment reassemble
+    # Create the zone file if it doesn't exist
+    if [[ ! -f "/var/nsd/zones/master/${domain}.zone" ]]; then
+      cat <<ZONE | doas tee /var/nsd/zones/master/$domain.zone > /dev/null
+\$ORIGIN $domain.
+\$TTL 3600
+
+@ IN SOA ns.brgen.no. hostmaster.$domain. (
+  $serial ; Serial
+  3600 ; Refresh
+  900 ; Retry
+  1209600 ; Expire
+  3600 ; Minimum TTL
+)
+@ IN NS ns.brgen.no.
+@ IN NS ns.hyp.net.
+ns.brgen.no. IN A $OPENBSD_AMSTERDAM_IP
+@ IN CAA 0 issue "letsencrypt.org"
+ZONE
+
+      # Optionally add CNAME records for subdomains if defined in domain_info
+      local subdomains=$(echo "$domain_info" | cut -d ':' -f 2)
+      if [[ -n "$subdomains" ]]; then
+        IFS=',' read -r -a subdomain_array <<< "$subdomains"
+        for subdomain in "${subdomain_array[@]}"; do
+          echo "$subdomain IN CNAME @" | doas tee -a "/var/nsd/zones/master/$domain.zone" > /dev/null
+        done
+      fi
+    fi
 
-# Relay rules (anchors) for relayd
-anchor "relayd/*"
+    # Sign the zone file with DNSSEC if not already signed
+    if [[ ! -f "/var/nsd/zones/master/${domain}.zone.signed" ]]; then
+      doas ldns-signzone -n -p -o "$domain" "/var/nsd/zones/master/$domain.zone"
+    fi
+  done
+
+  # Restart NSD to apply the configuration
+  echo "Enabling and starting NSD..."
+  doas rcctl enable nsd
+  doas rcctl restart nsd
+}
+
+configure_httpd_and_acme_client() {
+  # Generate a private key for Let's Encrypt if it doesn't exist
+  if [[ ! -f /etc/acme/letsencrypt-privkey.pem ]]; then
+    doas openssl genpkey -algorithm RSA -out /etc/acme/letsencrypt-privkey.pem -pkeyopt rsa_keygen_bits:2048
+  fi
+
+  # Configure httpd to serve ACME challenge responses
+  cat <<EOF | doas tee /etc/httpd.conf > /dev/null
+server "acme" {
+  listen on $OPENBSD_AMSTERDAM_IP port 80
+  location "/.well-known/acme-challenge/*" {
+    root "/var/www/acme"
+    request strip 2
+  }
+}
 EOF
 
-# Apply and test the pf(4) configuration
-if doas pfctl -n -f /etc/pf.conf; then
-  doas pfctl -f /etc/pf.conf
-  echo "pf(4) configured and applied." | tee -a $log_file
-else
-  echo "pf(4) configuration failed. Exiting." | tee -a $log_file
-  exit 1
-fi
-
-# HTTPD and ACME-Client Setup
-# This section sets up httpd(8) to handle ACME challenges for Let's Encrypt certificate issuance
-echo "Configuring httpd(8) and acme-client(1)..." | tee -a $log_file
-doas tee /etc/acme-client.conf > /dev/null << EOF
+  # Restart the httpd service to apply changes
+  doas rcctl restart httpd
+
+  # Set up the ACME client configuration file for Let's Encrypt
+  cat <<EOF | doas tee /etc/acme-client.conf > /dev/null
 authority letsencrypt {
   api url "https://acme-v02.api.letsencrypt.org/directory"
   account key "/etc/acme/letsencrypt-privkey.pem"
 }
+EOF
+
+  # Loop through all domains to configure ACME client for each
+  > /tmp/acme-client.conf.tmp # Initialize a new file to avoid concatenation errors
+  for domain_info in "${ALL_DOMAINS[@]}"; do
+    # Extract the primary domain from the string (before colon)
+    local domain="${domain_info%%:*}"
+
+    # If domain is empty, skip to the next one
+    [[ -z "$domain" ]] && continue
 
-domain $openbsd_amsterdam {
-  domain key "/etc/ssl/private/$openbsd_amsterdam.key"
-  domain full chain certificate "/etc/ssl/$openbsd_amsterdam.crt"
+    # Append the domain's ACME configuration
+    cat <<EOF >> /tmp/acme-client.conf.tmp
+domain $domain {
+  domain key "/etc/ssl/private/$domain.key"
+  domain fullchain "/etc/ssl/$domain.fullchain.pem"
   sign with letsencrypt
 }
 EOF
+  done
 
-# Configure httpd for serving ACME challenges
-doas tee /etc/httpd.conf > /dev/null << EOF
-server "acme-challenge" {
-  listen on $openbsd_amsterdam port 80
-  location "/.well-known/acme-challenge/*" {
-    root "/acme"
-    request strip 2
-  }
+  # Move the final ACME client configuration to the correct location
+  doas mv /tmp/acme-client.conf.tmp /etc/acme-client.conf
+
+  # Generate certificates for each domain if not already present
+  for domain_info in "${ALL_DOMAINS[@]}"; do
+    local domain="${domain_info%%:*}"
+    [[ -z "$domain" ]] && continue
+
+    if [[ ! -f "/etc/ssl/$domain.fullchain.pem" ]]; then
+      echo "Generating certificate for $domain using ACME client..."
+      doas acme-client -v "$domain"
+    else
+      echo "Certificate for $domain already exists, skipping ACME request."
+    fi
+  done
 }
-EOF
 
-doas mkdir -p /var/www/acme
-doas rcctl enable httpd
-doas rcctl start httpd
-echo "httpd(8) and acme-client(1) configured." | tee -a $log_file
+configure_relayd() {
+  local acme_client_port=$(generate_random_port)
+  local varnish_port=$(generate_random_port)
 
-# RELAYD Configuration for Reverse Proxying and TLS Termination
-# relayd(8) is used to handle HTTPS termination and proxy traffic to the Rails apps
-echo "Configuring relayd(8)..." | tee -a $log_file
-doas tee /etc/relayd.conf > /dev/null << EOF
+  cat <<EOF | doas tee /etc/relayd.conf > /dev/null
 log connection
 
-# Table for acme-client
-table <acme_client> { 127.0.0.1 }
-acme_client_port="$(generate_random_port)"
-EOF
-
-# Configure relayd for each app, assigning protocols and security headers
-for app in ${(k)apps_domains}; do
-  domain_port=${apps_domains[$app]}
-  domain=${domain_port%% *}
-  port=${domain_port##* }
+# Define a table for routing ACME client challenges to localhost
+table <acme_client> { 127.0.0.1:$acme_client_port }
 
-  cat <<- EOF | doas tee -a /etc/relayd.conf > /dev/null
-table <${app}> { 127.0.0.1 }
+# HTTP protocol for ACME challenges
+http protocol "filter_challenge" {
+  pass request path "/.well-known/acme-challenge/*" forward to <acme_client>
+}
 
-protocol "http_protocol_${app}" {
+# HTTP protocol for backend Varnish server
+http protocol "varnish_backend" {
   match request header set "X-Forwarded-By" value "\$SERVER_ADDR:\$SERVER_PORT"
   match request header set "X-Forwarded-For" value "\$REMOTE_ADDR"
-  match response header set "Content-Security-Policy" value "default-src https:; style-src 'self' 'unsafe-inline';"
   match response header set "Strict-Transport-Security" value "max-age=31536000; includeSubDomains; preload"
   match response header set "X-Frame-Options" value "SAMEORIGIN"
-
-  tcp { no delay }
-
-  request timeout 20
-  session timeout 60
-  forward to <${app}> port $port
+  match response header set "Content-Security-Policy" value "upgrade-insecure-requests"
+  match response header set "X-Content-Type-Options" value "nosniff"
+  match response header set "Referrer-Policy" value "no-referrer"
+  match response header set "Permissions-Policy" value "geolocation=*"
 }
 
-relay "http_${app}" {
-  listen on $openbsd_amsterdam port http
-  protocol "http_protocol_${app}"
+relay "acme_relay" {
+  listen on $OPENBSD_AMSTERDAM_IP port 80
+  forward to 127.0.0.1 port $acme_client_port protocol "filter_challenge"
 }
 
-relay "https_${app}" {
-  listen on $openbsd_amsterdam port https tls
-  protocol "http_protocol_${app}"
-  tls keypair "$domain"
-  mode source-hash
+relay "https_relay" {
+  listen on $OPENBSD_AMSTERDAM_IP port 443 tls
+  protocol "varnish_backend"
+  forward to 127.0.0.1 port $varnish_port
 }
 EOF
-done
 
-# Apply relayd configuration and restart service
-if doas relayctl load /etc/relayd.conf; then
   doas rcctl restart relayd
-  echo "relayd(8) configured and restarted." | tee -a $log_file
-else
-  echo "relayd(8) configuration failed. Exiting." | tee -a $log_file
-  exit 1
-fi
-
-# NSD Configuration for DNS management
-# This section configures nsd(8) to act as the authoritative DNS server for the domains
-echo "Configuring nsd(8)..." | tee -a $log_file
-doas mkdir -p /var/nsd/zones/master /var/nsd/etc
-
-# Loop through each domain and create zone files for DNS resolution
-for domain in ${(k)all_domains}; do
-  serial=$(date +"%Y%m%d%H")
-  cat <<- EOF | doas tee "/var/nsd/zones/master/$domain.zone" > /dev/null
-\$ORIGIN $domain.
-\$TTL 24h
-@ IN SOA ns.brgen.no. admin.brgen.no. ($serial 1h 15m 1w 3m)
-@ IN NS ns.brgen.no.
-@ IN NS ns.hyp.net.
-$domain. 3m IN CAA 0 issue "letsencrypt.org"
-www IN CNAME @
-@ IN A $openbsd_amsterdam
-EOF
+}
 
-  # Add subdomains to zone files
-  if [[ -n "${all_domains[$domain]}" ]]; then
-    for subdomain in ${(s: :)all_domains[$domain]}; do
-      echo "$subdomain IN A $openbsd_amsterdam" | doas tee -a "/var/nsd/zones/master/$domain.zone" > /dev/null
-    done
-  fi
-done
+configure_varnish() {
+  local varnish_port=$(generate_random_port)
+  local falcon_backend_port=$(generate_random_port)
 
-# Configure the NSD server with the new zone files
-cat <<- EOF | doas tee /var/nsd/etc/nsd.conf > /dev/null
-server:
-  ip-address: "$openbsd_amsterdam"
-  hide-version: yes
-  zonesdir: "/var/nsd/zones"
-  verbosity: 2
-
-remote-control:
-  control-enable: yes
-  control-interface: 127.0.0.1
-  control-port: 8952
-  server-key-file: "/var/nsd/etc/nsd_server.key"
-  server-cert-file: "/var/nsd/etc/nsd_server.pem"
-  control-key-file: "/var/nsd/etc/nsd_control.key"
-  control-cert-file: "/var/nsd/etc/nsd_control.pem"
-EOF
+  cat <<EOF | doas tee /etc/varnish/default.vcl > /dev/null
+vcl 4.0;
 
-# Add zone configurations for each domain
-for domain in ${(k)all_domains}; do
-  cat <<- EOF | doas tee -a /var/nsd/etc/nsd.conf > /dev/null
-zone:
-  name: "$domain"
-  zonefile: "master/$domain.zone"
-  allow-notify: $hyp_net NOKEY
-  provide-xfr: $hyp_net NOKEY
-EOF
-done
+backend default {
+  .host = "127.0.0.1";
+  .port = "$falcon_backend_port";
+}
 
-# Apply NSD configuration and start service
-if doas nsd-checkconf /var/nsd/etc/nsd.conf; then
-  doas rcctl enable nsd
-  doas rcctl start nsd
-  echo "nsd(8) configured and started." | tee -a $log_file
-else
-  echo "nsd(8) configuration failed. Exiting." | tee -a $log_file
-  exit 1
-fi
-
-# PostgreSQL setup for database management
-# Initialize PostgreSQL database cluster and enable service
-echo "Configuring PostgreSQL..." | tee -a $log_file
-doas su - _postgresql -c "/usr/local/bin/initdb -D /var/postgresql/data"
-doas rcctl enable postgresql
-doas rcctl start postgresql
-check_service_status "postgresql"
-
-# Redis and Varnish setup for caching and performance
-echo "Configuring Redis and Varnish..." | tee -a $log_file
-doas rcctl enable redis
-doas rcctl start redis
-check_service_status "redis"
-
-doas rcctl enable varnish
-doas rcctl start varnish
-check_service_status "varnish"
-
-# Monit setup for monitoring and alerting
-# Monit is used to monitor and automatically restart services if they fail
-echo "Setting up monitoring with Monit..." | tee -a $log_file
-doas tee /etc/monitrc > /dev/null << "EOF"
-set daemon 60
-set logfile /var/log/monit.log
-
-# Monitor relayd
-check process relayd with pidfile /var/run/relayd.pid
-  start program = "/usr/sbin/rcctl start relayd"
-  stop program  = "/usr/sbin/rcctl stop relayd"
-  if 5 restarts within 5 cycles then exec "/usr/sbin/rcctl restart relayd"
-
-# Monitor nsd
-check process nsd with pidfile /var/run/nsd.pid
-  start program = "/usr/sbin/rcctl start nsd"
-  stop program  = "/usr/sbin/rcctl stop nsd"
-  if 5 restarts within 5 cycles then exec "/usr/sbin/rcctl restart nsd"
-
-# Monitor redis
-check process redis with pidfile /var/run/redis/redis-server.pid
-  start program = "/usr/sbin/rcctl start redis"
-  stop program  = "/usr/sbin/rcctl stop redis"
-  if 5 restarts within 5 cycles then exec "/usr/sbin/rcctl restart redis"
-
-# Monitor varnish
-check process varnish with pidfile /var/run/varnishd.pid
-  start program = "/usr/sbin/rcctl start varnish"
-  stop program  = "/usr/sbin/rcctl stop varnish"
-  if 5 restarts within 5 cycles then exec "/usr/sbin/rcctl restart varnish"
+sub vcl_recv {
+  if (req.url ~ "^/assets/") {
+    unset req.http.cookie;
+  }
+}
+
+sub vcl_backend_response {
+  if (beresp.status == 200) {
+    set beresp.ttl = 1h;
+  }
+}
 EOF
 
-# Start Monit service
-doas rcctl enable monit
-doas rcctl start monit
-echo "Monit configured and started." | tee -a $log_file
+  doas rcctl set varnishd flags "-a :$varnish_port -b localhost:$falcon_backend_port"
+  doas rcctl start varnishd
+}
+
+configure_startup_scripts() {
+  for app in "${RAILS_APPS[@]}"; do
+    if ! doas grep -q "^$app:" /etc/master.passwd; then
+      doas useradd -m -s /bin/ksh "$app"
+    fi
+
+    local backend_port=$(generate_random_port)
+
+    cat <<EOF | doas tee "/etc/rc.d/$app" > /dev/null
+#!/bin/ksh
 
-# Automated ACME certificate renewal
-# This cron job automatically renews SSL/TLS certificates
-echo "Setting up automated ACME certificate renewal..." | tee -a $log_file
-echo "0 0 * * * root /usr/bin/doas acme-client -vAD $openbsd_amsterdam && rcctl reload relayd" | doas tee /etc/cron.d/acme-renew
+daemon="/bin/ksh -c 'cd /home/$app/$app && export RAILS_ENV=production && /usr/local/bin/bundle exec falcon serve -b tcp://127.0.0.1:$backend_port'"
+daemon_user="$app"
 
-# Run final health checks
-echo "Running final health checks..." | tee -a $log_file
-run_health_checks
+unveil -r /home/$app/$app
+unveil /var/www/log
+unveil /etc/ssl
+unveil
+
+pledge stdio rpath wpath cpath inet
+
+. /etc/rc.d/rc.subr
+rc_cmd \$1
+EOF
+
+    doas chmod +x "/etc/rc.d/$app"
+    doas rcctl enable "$app"
+    doas rcctl start "$app"
+  done
+}
+
+main() {
+  install_packages
+  configure_pf
+  configure_nsd
+  configure_httpd_and_acme_client
+  configure_relayd
+  configure_varnish
+  configure_startup_scripts
+}
 
-echo "OpenBSD setup completed successfully." | tee -a $log_file
+main "$@"
 

commit 7b970fcb053044d96e8784b6ed6dd4fcaa0f31a1
Author: dev <dev@dev.openbsd.amsterdam>
Date:   Tue Oct 29 03:13:29 2024 +0100

    TMP

diff --git a/openbsd.sh b/openbsd.sh
index 83594ee..245296a 100644
--- a/openbsd.sh
+++ b/openbsd.sh
@@ -1,262 +1,347 @@
 #!/usr/bin/env zsh
 
-# OpenBSD & Ruby on Rails setup script
-
-# Configuration Variables
-OPENBSD_AMSTERDAM="46.23.95.45"
-HYP_NET="194.63.248.53"
-EXT_IF="vio0"
-LOG_FILE="openbsd_setup.log"
-
-# --
+openbsd_amsterdam="46.23.95.45"
+log_file="/var/log/openbsd_setup.log"
+hyp_net="194.63.248.53"
+ext_if="vio0"
+
+# Initial setup and logging
+echo "Configuring OpenBSD for Ruby on Rails..." | tee -a $log_file
+
+# Function to generate a random port within a safe range and avoid port collisions
+generate_random_port() {
+  local port
+  port=$((RANDOM % 64511 + 1024))
+  while sockstat -l | grep -q ":$port"; do
+    port=$((RANDOM % 64511 + 1024))
+  done
+  echo $port
+}
 
+# Define domains and apps
+# This map assigns each domain to its respective apps and will be used later to configure services
 typeset -A all_domains=(
-  ["brgen.no"]=("markedsplass" "playlist" "dating" "tv" "takeaway" "maps")
-  ["oshlo.no"]=("markedsplass" "playlist" "dating" "tv" "takeaway" "maps")
-  ["trndheim.no"]=("markedsplass" "playlist" "dating" "tv" "takeaway" "maps")
-  ["stvanger.no"]=("markedsplass" "playlist" "dating" "tv" "takeaway" "maps")
-  ["trmso.no"]=("markedsplass" "playlist" "dating" "tv" "takeaway" "maps")
-  ["longyearbyn.no"]=("markedsplass" "playlist" "dating" "tv" "takeaway" "maps")
-  ["reykjavk.is"]=("markadur" "playlist" "dating" "tv" "takeaway" "maps")
-  ["kobenhvn.dk"]=("markedsplads" "playlist" "dating" "tv" "takeaway" "maps")
-  ["stholm.se"]=("marknadsplats" "playlist" "dating" "tv" "takeaway" "maps")
-  ["mlmoe.se"]=("marknadsplats" "playlist" "dating" "tv" "takeaway" "maps")
-  ["hlsinki.fi"]=("markkinapaikka" "playlist" "dating" "tv" "takeaway" "maps")
-  ["lndon.uk"]=("marketplace" "playlist" "dating" "tv" "takeaway" "maps")
-  ["mnchester.uk"]=("marketplace" "playlist" "dating" "tv" "takeaway" "maps")
-  ["pub.healthcare"]=""
-  ["pub.attorney"]=""
-  ["freehelp.legal"]=""
-  ["bsdports.org"]=""
-  ["discordb.org"]=""
-  ["foodielicio.us"]=""
-  ["sortmyshit.com"]=""
-  ["neurotica.fashion"]=""
+  ["brgen.no"]="markedsplass playlist dating tv takeaway maps"
+  ["oshlo.no"]="markedsplass playlist dating tv takeaway maps"
+  ["trndheim.no"]="markedsplass playlist dating tv takeaway maps"
+  ["stvanger.no"]="markedsplass playlist dating tv takeaway maps"
+  ["trmso.no"]="markedsplass playlist dating tv takeaway maps"
+  ["longyearbyn.no"]="markedsplass playlist dating tv takeaway maps"
+  ["reykjavk.is"]="markadur playlist dating tv takeaway maps"
+  ["kobenhvn.dk"]="markedsplads playlist dating tv takeaway maps"
+  ["stholm.se"]="marknadsplats playlist dating tv takeaway maps"
+  ["gteborg.se"]="marknadsplats playlist dating tv takeaway maps"
+  ["mlmoe.se"]="marknadsplats playlist dating tv takeaway maps"
+  ["hlsinki.fi"]="markkinapaikka playlist dating tv takeaway maps"
+  ["lndon.uk"]="marketplace playlist dating tv takeaway maps"
+  ["mnchester.uk"]="marketplace playlist dating tv takeaway maps"
+  ["brmingham.uk"]="marketplace playlist dating tv takeaway maps"
+  ["edinbrgh.uk"]="marketplace playlist dating tv takeaway maps"
+  ["glasgw.uk"]="marketplace playlist dating tv takeaway maps"
+  ["lverpool.uk"]="marketplace playlist dating tv takeaway maps"
+  ["amstrdam.nl"]="marktplaats playlist dating tv takeaway maps"
+  ["rottrdam.nl"]="marktplaats playlist dating tv takeaway maps"
+  ["utrcht.nl"]="marktplaats playlist dating tv takeaway maps"
+  ["brssels.be"]="marche playlist dating tv takeaway maps"
+  ["zrich.ch"]="marktplatz playlist dating tv takeaway maps"
+  ["lchtenstein.li"]="marktplatz playlist dating tv takeaway maps"
+  ["frankfrt.de"]="marktplatz playlist dating tv takeaway maps"
+  ["mrseille.fr"]="marche playlist dating tv takeaway maps"
+  ["mlan.it"]="mercato playlist dating tv takeaway maps"
+  ["lsbon.pt"]="mercado playlist dating tv takeaway maps"
+  ["lsangeles.com"]="marketplace playlist dating tv takeaway maps"
 )
 
-# Shared Functions
-log_message() {
-  local level="${1:-INFO}"
-  local message="$2"
-  echo "$(date +%Y-%m-%dT%H:%M:%S) [$level] $message" | tee -a "$LOG_FILE"
-}
+# Allocate dynamic ports for each app under each domain
+typeset -A apps_domains
+for domain in ${(k)all_domains}; do
+  for app in ${(s: :)all_domains[$domain]}; do
+    apps_domains["$app-$domain"]="127.0.0.1:$(generate_random_port)"
+  done
+done
 
+# -- INSTALLATION BEGIN --
+# Install necessary packages: Ruby, PostgreSQL, Redis, Varnish, DNS, and security tools
+echo "Installing necessary packages..." | tee -a $log_file
 retry_command() {
   local retries=3
   local delay=5
-  while (( retries > 0 )); do
-    "$@" && return 0
-    log_message "WARN" "Command failed: $@. Retrying... ($retries attempts left)"
-    ((retries--))
-    sleep $delay
+  local count=0
+  while (( count < retries )); do
+    if "$@"; then
+      return 0
+    else
+      ((count++))
+      echo "Retrying in $delay seconds..." | tee -a $log_file
+      sleep $delay
+    fi
   done
-  log_message "ERROR" "Command failed after multiple attempts: $@. Exiting."
-  exit 1
+  return 1
 }
 
-# Install Necessary Packages
-log_message "INFO" "Installing necessary packages..."
-packages=(ruby-3.3.5 postgresql-server dnscrypt-proxy redis varnish)
-
-for package in "${packages[@]}"; do
-  if ! pkg_info | grep -q "$package"; then
-    retry_command doas pkg_add "$package"
-    if [[ $? -ne 0 ]]; then
-      log_message "ERROR" "Failed to install package: $package"
-      exit 1
-    fi
-  else
-    log_message "INFO" "Package $package is already installed."
-  fi
-  retry_command pkg_info "$package"
-  log_message "DEBUG" "Package $package verified successfully."
-done
-log_message "INFO" "All packages verified."
-
-# Configure pf with improved SSH rules
-log_message "INFO" "Configuring pf..."
-tmp_pf_conf=$(mktemp)
-if [[ $? -ne 0 ]]; then
-  log_message "ERROR" "Failed to create temporary file for pf configuration."
+if ! retry_command doas pkg_add -UI ruby postgresql-server dnscrypt-proxy sshguard monit redis varnish; then
+  echo "Package installation failed. Exiting." | tee -a $log_file
   exit 1
 fi
+echo "Packages installed successfully." | tee -a $log_file
 
-log_message "DEBUG" "Writing pf configuration to temporary file $tmp_pf_conf."
-cat << EOF > "$tmp_pf_conf"
-ext_if = "$EXT_IF"
-
-# Allow all loopback traffic
-set skip on lo
-
-# Block stateless traffic and return RSTs
-block return
+# PF (Packet Filter) Configuration
+# This configures the OpenBSD firewall, blocking unwanted traffic and allowing only essential services like SSH, HTTP, HTTPS, and DNS
+echo "Configuring pf(4)..." | tee -a $log_file
+doas tee /etc/pf.conf > /dev/null << EOF
+ext_if = "$ext_if"
 
-# Default pass rule to keep state
-pass
+set skip on lo  # Skip loopback interface
+block return  # Block all traffic by default
+pass  # Allow traffic based on subsequent rules
 
-# Block all incoming traffic by default and log
-block in log
-
-# Allow all outgoing traffic by default
-pass out quick
-
-# Block brute-force attackers
+# Brute-force protection: Blocks IPs that exceed connection limits on SSH
 table <bruteforce> persist
 block quick from <bruteforce>
 
-# Rate-limit SSH for other IPs
-pass in on $EXT_IF inet proto tcp from any to $EXT_IF port 22 keep state (max-src-conn 15, max-src-conn-rate 5/3, overload <bruteforce> flush global)
+# Allow SSH with relaxed rate-limiting to prevent accidental lockout
+pass in on \$ext_if inet proto tcp from any to \$ext_if port 22 keep state (max-src-conn 50, max-src-conn-rate 20/60, overload <bruteforce> flush global)
 
-# Allow DNS requests and zone transfers
-pass in on $EXT_IF inet proto { tcp, udp } from any to $EXT_IF port 53 keep state
+# Allow DNS (both TCP and UDP)
+pass in on \$ext_if inet proto { tcp, udp } from any to \$ext_if port 53 keep state
 
 # Allow HTTP and HTTPS traffic
-pass in on $EXT_IF inet proto tcp from any to $EXT_IF port { 80, 443 } keep state
+pass in on \$ext_if inet proto tcp from any to \$ext_if port { 80, 443 } keep state
 
-# Include relayd rules if installed
+# Enable packet scrubbing (fragment reassembly)
+scrub in on \$ext_if all fragment reassemble
+
+# Relay rules (anchors) for relayd
 anchor "relayd/*"
 EOF
 
-# Test and load the pf configuration
-log_message "DEBUG" "Testing pf configuration."
-retry_command doas pfctl -n -f "$tmp_pf_conf"
-if [[ $? -ne 0 ]]; then
-  log_message "ERROR" "pfctl test failed for pf configuration. Please check the configuration."
-  cat "$tmp_pf_conf"
+# Apply and test the pf(4) configuration
+if doas pfctl -n -f /etc/pf.conf; then
+  doas pfctl -f /etc/pf.conf
+  echo "pf(4) configured and applied." | tee -a $log_file
+else
+  echo "pf(4) configuration failed. Exiting." | tee -a $log_file
   exit 1
 fi
 
-# Copy the configuration file if the test passes
-retry_command doas cp "$tmp_pf_conf" /etc/pf.conf
-if [[ $? -ne 0 ]]; then
-  log_message "ERROR" "Failed to copy pf.conf to /etc/. Check permissions."
-  exit 1
-fi
+# HTTPD and ACME-Client Setup
+# This section sets up httpd(8) to handle ACME challenges for Let's Encrypt certificate issuance
+echo "Configuring httpd(8) and acme-client(1)..." | tee -a $log_file
+doas tee /etc/acme-client.conf > /dev/null << EOF
+authority letsencrypt {
+  api url "https://acme-v02.api.letsencrypt.org/directory"
+  account key "/etc/acme/letsencrypt-privkey.pem"
+}
 
-# Clean up temporary file
-if [[ -f "$tmp_pf_conf" ]]; then
-  rm "$tmp_pf_conf"
-  if [[ $? -ne 0 ]]; then
-    log_message "WARN" "Failed to delete temporary file $tmp_pf_conf. Manual cleanup might be required."
-  fi
-fi
+domain $openbsd_amsterdam {
+  domain key "/etc/ssl/private/$openbsd_amsterdam.key"
+  domain full chain certificate "/etc/ssl/$openbsd_amsterdam.crt"
+  sign with letsencrypt
+}
+EOF
 
-# Load pf configuration
-log_message "DEBUG" "Loading pf configuration."
-retry_command doas pfctl -f /etc/pf.conf
-if [[ $? -ne 0 ]]; then
-  log_message "ERROR" "Failed to load pf.conf. Check the configuration for errors."
-  exit 1
-fi
+# Configure httpd for serving ACME challenges
+doas tee /etc/httpd.conf > /dev/null << EOF
+server "acme-challenge" {
+  listen on $openbsd_amsterdam port 80
+  location "/.well-known/acme-challenge/*" {
+    root "/acme"
+    request strip 2
+  }
+}
+EOF
 
-# Enable pf if not already enabled
-if ! doas pfctl -s info | grep -q "Status: Enabled"; then
-  retry_command doas pfctl -e
-  if [[ $? -eq 0 ]]; then
-    log_message "INFO" "pf configured and enabled."
-  else
-    log_message "ERROR" "Failed to enable pf. Please check the system logs."
-    exit 1
-  fi
-else
-  log_message "INFO" "pf is already enabled and configured."
-fi
+doas mkdir -p /var/www/acme
+doas rcctl enable httpd
+doas rcctl start httpd
+echo "httpd(8) and acme-client(1) configured." | tee -a $log_file
 
-# Enable pf to start at boot after verification
-retry_command doas rcctl enable pf
-if [[ $? -ne 0 ]]; then
-  log_message "ERROR" "Failed to enable pf for startup. Please check rcctl configuration."
-  exit 1
-fi
+# RELAYD Configuration for Reverse Proxying and TLS Termination
+# relayd(8) is used to handle HTTPS termination and proxy traffic to the Rails apps
+echo "Configuring relayd(8)..." | tee -a $log_file
+doas tee /etc/relayd.conf > /dev/null << EOF
+log connection
 
-# Enable and configure other services (relayd, NSD, OpenSMTPD, etc.)
-manage_service() {
-  local service_name="$1"
-  local action="$2"
-  retry_command doas rcctl "$action" "$service_name"
-  if [[ $? -ne 0 ]]; then
-    log_message "ERROR" "Failed to $action $service_name. Please check logs."
-    exit 1
-  fi
+# Table for acme-client
+table <acme_client> { 127.0.0.1 }
+acme_client_port="$(generate_random_port)"
+EOF
+
+# Configure relayd for each app, assigning protocols and security headers
+for app in ${(k)apps_domains}; do
+  domain_port=${apps_domains[$app]}
+  domain=${domain_port%% *}
+  port=${domain_port##* }
+
+  cat <<- EOF | doas tee -a /etc/relayd.conf > /dev/null
+table <${app}> { 127.0.0.1 }
+
+protocol "http_protocol_${app}" {
+  match request header set "X-Forwarded-By" value "\$SERVER_ADDR:\$SERVER_PORT"
+  match request header set "X-Forwarded-For" value "\$REMOTE_ADDR"
+  match response header set "Content-Security-Policy" value "default-src https:; style-src 'self' 'unsafe-inline';"
+  match response header set "Strict-Transport-Security" value "max-age=31536000; includeSubDomains; preload"
+  match response header set "X-Frame-Options" value "SAMEORIGIN"
+
+  tcp { no delay }
+
+  request timeout 20
+  session timeout 60
+  forward to <${app}> port $port
 }
 
-# Configuring relayd
-log_message "INFO" "Configuring relayd..."
-tmp_relayd_conf=$(mktemp)
-if [[ $? -ne 0 ]]; then
-  log_message "ERROR" "Failed to create temporary file for relayd configuration."
-  exit 1
-fi
-log_message "DEBUG" "Writing relayd configuration to temporary file $tmp_relayd_conf."
-cat << EOF > "$tmp_relayd_conf"
-log connection
+relay "http_${app}" {
+  listen on $openbsd_amsterdam port http
+  protocol "http_protocol_${app}"
+}
 
-# Define backend table
-table <backend> { 127.0.0.1 }
-
-# Example relay rule for HTTP traffic
-relay "http_relay" {
-  listen on $EXT_IF port 80
-  forward to <backend> port 8080
-  protocol "http" {
-    match request header set "X-Forwarded-For" value "\$REMOTE_ADDR"
-    match request header set "X-Forwarded-Host" value "\$HTTP_HOST"
-    match request header set "X-Forwarded-Proto" value "http"
-  }
-  connection timeout 300
+relay "https_${app}" {
+  listen on $openbsd_amsterdam port https tls
+  protocol "http_protocol_${app}"
+  tls keypair "$domain"
+  mode source-hash
 }
 EOF
+done
 
-# Test relayd configuration before applying
-log_message "DEBUG" "Testing relayd configuration."
-retry_command doas relayd -n -f "$tmp_relayd_conf"
-if [[ $? -ne 0 ]]; then
-  log_message "ERROR" "relayd configuration test failed. Please check the configuration."
-  cat "$tmp_relayd_conf"
+# Apply relayd configuration and restart service
+if doas relayctl load /etc/relayd.conf; then
+  doas rcctl restart relayd
+  echo "relayd(8) configured and restarted." | tee -a $log_file
+else
+  echo "relayd(8) configuration failed. Exiting." | tee -a $log_file
   exit 1
 fi
 
-retry_command doas cp "$tmp_relayd_conf" /etc/relayd.conf
-rm "$tmp_relayd_conf"
+# NSD Configuration for DNS management
+# This section configures nsd(8) to act as the authoritative DNS server for the domains
+echo "Configuring nsd(8)..." | tee -a $log_file
+doas mkdir -p /var/nsd/zones/master /var/nsd/etc
+
+# Loop through each domain and create zone files for DNS resolution
+for domain in ${(k)all_domains}; do
+  serial=$(date +"%Y%m%d%H")
+  cat <<- EOF | doas tee "/var/nsd/zones/master/$domain.zone" > /dev/null
+\$ORIGIN $domain.
+\$TTL 24h
+@ IN SOA ns.brgen.no. admin.brgen.no. ($serial 1h 15m 1w 3m)
+@ IN NS ns.brgen.no.
+@ IN NS ns.hyp.net.
+$domain. 3m IN CAA 0 issue "letsencrypt.org"
+www IN CNAME @
+@ IN A $openbsd_amsterdam
+EOF
 
-manage_service relayd enable
-manage_service relayd start
+  # Add subdomains to zone files
+  if [[ -n "${all_domains[$domain]}" ]]; then
+    for subdomain in ${(s: :)all_domains[$domain]}; do
+      echo "$subdomain IN A $openbsd_amsterdam" | doas tee -a "/var/nsd/zones/master/$domain.zone" > /dev/null
+    done
+  fi
+done
 
-# Enable OpenSMTPD to start at boot after verifying configuration
-log_message "INFO" "Configuring OpenSMTPD..."
-retry_command doas smtpd -n -f /etc/mail/smtpd.conf
-if [[ $? -ne 0 ]]; then
-  log_message "ERROR" "OpenSMTPD configuration test failed. Please check the configuration."
-  cat /etc/mail/smtpd.conf
+# Configure the NSD server with the new zone files
+cat <<- EOF | doas tee /var/nsd/etc/nsd.conf > /dev/null
+server:
+  ip-address: "$openbsd_amsterdam"
+  hide-version: yes
+  zonesdir: "/var/nsd/zones"
+  verbosity: 2
+
+remote-control:
+  control-enable: yes
+  control-interface: 127.0.0.1
+  control-port: 8952
+  server-key-file: "/var/nsd/etc/nsd_server.key"
+  server-cert-file: "/var/nsd/etc/nsd_server.pem"
+  control-key-file: "/var/nsd/etc/nsd_control.key"
+  control-cert-file: "/var/nsd/etc/nsd_control.pem"
+EOF
+
+# Add zone configurations for each domain
+for domain in ${(k)all_domains}; do
+  cat <<- EOF | doas tee -a /var/nsd/etc/nsd.conf > /dev/null
+zone:
+  name: "$domain"
+  zonefile: "master/$domain.zone"
+  allow-notify: $hyp_net NOKEY
+  provide-xfr: $hyp_net NOKEY
+EOF
+done
+
+# Apply NSD configuration and start service
+if doas nsd-checkconf /var/nsd/etc/nsd.conf; then
+  doas rcctl enable nsd
+  doas rcctl start nsd
+  echo "nsd(8) configured and started." | tee -a $log_file
+else
+  echo "nsd(8) configuration failed. Exiting." | tee -a $log_file
   exit 1
 fi
 
-manage_service smtpd enable
-manage_service smtpd start
-
-# Create rc.d startup scripts for all apps dynamically from domains.conf
-log_message "INFO" "Creating rc.d startup scripts for all apps..."
-for app in "${(@k)all_domains}"; do
-  cat << EOF | doas tee "/etc/rc.d/$app" > /dev/null
-#!/bin/ksh
-#
-# Startup script for $app
-#
-. /etc/rc.subr
-
-name="$app"
-rcvar="\${name}_enable"
-command="/usr/local/bin/$app"
-command_args="start"
-
-load_rc_config \$name
-run_rc_command "\$1"
+# PostgreSQL setup for database management
+# Initialize PostgreSQL database cluster and enable service
+echo "Configuring PostgreSQL..." | tee -a $log_file
+doas su - _postgresql -c "/usr/local/bin/initdb -D /var/postgresql/data"
+doas rcctl enable postgresql
+doas rcctl start postgresql
+check_service_status "postgresql"
+
+# Redis and Varnish setup for caching and performance
+echo "Configuring Redis and Varnish..." | tee -a $log_file
+doas rcctl enable redis
+doas rcctl start redis
+check_service_status "redis"
+
+doas rcctl enable varnish
+doas rcctl start varnish
+check_service_status "varnish"
+
+# Monit setup for monitoring and alerting
+# Monit is used to monitor and automatically restart services if they fail
+echo "Setting up monitoring with Monit..." | tee -a $log_file
+doas tee /etc/monitrc > /dev/null << "EOF"
+set daemon 60
+set logfile /var/log/monit.log
+
+# Monitor relayd
+check process relayd with pidfile /var/run/relayd.pid
+  start program = "/usr/sbin/rcctl start relayd"
+  stop program  = "/usr/sbin/rcctl stop relayd"
+  if 5 restarts within 5 cycles then exec "/usr/sbin/rcctl restart relayd"
+
+# Monitor nsd
+check process nsd with pidfile /var/run/nsd.pid
+  start program = "/usr/sbin/rcctl start nsd"
+  stop program  = "/usr/sbin/rcctl stop nsd"
+  if 5 restarts within 5 cycles then exec "/usr/sbin/rcctl restart nsd"
+
+# Monitor redis
+check process redis with pidfile /var/run/redis/redis-server.pid
+  start program = "/usr/sbin/rcctl start redis"
+  stop program  = "/usr/sbin/rcctl stop redis"
+  if 5 restarts within 5 cycles then exec "/usr/sbin/rcctl restart redis"
+
+# Monitor varnish
+check process varnish with pidfile /var/run/varnishd.pid
+  start program = "/usr/sbin/rcctl start varnish"
+  stop program  = "/usr/sbin/rcctl stop varnish"
+  if 5 restarts within 5 cycles then exec "/usr/sbin/rcctl restart varnish"
 EOF
-  retry_command doas chmod +x "/etc/rc.d/$app"
-done
 
-log_message "INFO" "All app startup scripts created."
+# Start Monit service
+doas rcctl enable monit
+doas rcctl start monit
+echo "Monit configured and started." | tee -a $log_file
+
+# Automated ACME certificate renewal
+# This cron job automatically renews SSL/TLS certificates
+echo "Setting up automated ACME certificate renewal..." | tee -a $log_file
+echo "0 0 * * * root /usr/bin/doas acme-client -vAD $openbsd_amsterdam && rcctl reload relayd" | doas tee /etc/cron.d/acme-renew
 
-log_message "INFO" "Setup script completed successfully."
+# Run final health checks
+echo "Running final health checks..." | tee -a $log_file
+run_health_checks
 
+echo "OpenBSD setup completed successfully." | tee -a $log_file
 

commit 17a7841c606a2fa6d5ae2dbcd84d9cd8b772b7c6
Author: dev <dev@dev.openbsd.amsterdam>
Date:   Mon Oct 28 20:50:47 2024 +0100

    TMP

diff --git a/README.md b/README.md
new file mode 100644
index 0000000..a9a7228
--- /dev/null
+++ b/README.md
@@ -0,0 +1,95 @@
+# __openbsd.sh Setup Script
+
+## Overview
+
+This script automates the setup of an OpenBSD environment configured for Ruby on Rails development. It includes the installation of required packages, configuration of firewall rules using Packet Filter (pf), relayd setup for reverse proxying, and NSD setup for DNS management.
+
+## Features
+
+- **Automatic Package Installation**: Installs required packages such as Ruby, PostgreSQL, Redis, and others.
+- **Dynamic Domain Loading**: Loads domains from an external configuration file for easy management and maintainability.
+- **Firewall Configuration (pf)**: Configures OpenBSD's Packet Filter to enhance security, including brute-force attack protection and trusted IP handling for SSH.
+- **Reverse Proxy Configuration (relayd)**: Sets up relayd for HTTP traffic to support load balancing and forwarding.
+- **DNS Configuration (NSD)**: Automates the creation of zone files for managing DNS entries across various domains and subdomains.
+
+## Prerequisites
+
+- OpenBSD system with `doas` configured.
+- Configuration file `/etc/openbsd_domains.conf` with the domains and subdomains to be managed.
+- Internet access for package installation.
+
+## Usage
+
+### Running the Script
+
+To execute the script, run the following command:
+
+    ./__openbsd.sh
+
+Ensure the script has executable permissions:
+
+    chmod +x __openbsd.sh
+
+### Configuration File
+
+The domains to be managed are loaded from `/etc/openbsd_domains.conf`. This file should contain the domain definitions in the format expected by the script, allowing for easy updates without modifying the script itself.
+
+## Detailed Steps
+
+### 1. Package Installation
+
+The script installs several necessary packages:
+
+- `ruby`: Ruby programming language.
+- `postgresql-server`: Database server for Rails.
+- `dnscrypt-proxy`: DNS security.
+- `redis`: In-memory data store.
+- `varnish`: HTTP reverse proxy.
+
+The latest version of each package is determined and installed using OpenBSD's `pkg_add` tool.
+
+### 2. Packet Filter (pf) Configuration
+
+- Configures `pf` to block unwanted incoming traffic by default.
+- Protects against brute-force attacks by rate-limiting SSH connections and blocking offending IPs.
+- Allows incoming connections for HTTP, HTTPS, DNS, and SSH (from trusted IPs).
+- Loads the configuration from a temporary file and applies it.
+
+### 3. Relayd Configuration
+
+- Configures `relayd` for HTTP traffic management.
+- Sets up a backend table for local services (`127.0.0.1`) and listens for incoming HTTP requests on port 80.
+- Copies the generated configuration to `/etc/relayd.conf`.
+
+### 4. NSD (Name Server Daemon) Configuration
+
+- Sets up zone files for each domain listed in `/etc/openbsd_domains.conf`.
+- Configures SOA, NS, and A records for the domains and their respective subdomains.
+- Utilizes a timestamp as the serial number for SOA records to ensure DNS changes are properly propagated.
+
+## Logs
+
+- All log messages generated by the script are written to `/var/log/openbsd_setup.log` for auditing and troubleshooting purposes.
+
+## Error Handling
+
+- The script includes retry mechanisms for package installation and configuration steps to handle transient issues.
+- If any critical step fails after multiple attempts, the script will exit and log the failure.
+
+## Notes
+
+- Ensure that the `/etc/openbsd_domains.conf` file is properly formatted and contains the correct domain information before running the script.
+- This script is intended for environments where `doas` is used instead of `sudo`.
+
+## Example `/etc/openbsd_domains.conf` Format
+
+    typeset -A all_domains=(
+      ["example.com"]=("www" "blog" "shop")
+      ["anotherdomain.com"]=("api" "app" "static")
+    )
+
+This format allows you to specify the main domains and their respective subdomains, which the script will use to generate the appropriate DNS zone files.
+
+## Disclaimer
+
+This script is provided as-is and should be tested in a development environment before using it in production. Make sure to adjust configurations to match your specific use case and security requirements.
diff --git a/openbsd.sh b/openbsd.sh
new file mode 100644
index 0000000..83594ee
--- /dev/null
+++ b/openbsd.sh
@@ -0,0 +1,262 @@
+#!/usr/bin/env zsh
+
+# OpenBSD & Ruby on Rails setup script
+
+# Configuration Variables
+OPENBSD_AMSTERDAM="46.23.95.45"
+HYP_NET="194.63.248.53"
+EXT_IF="vio0"
+LOG_FILE="openbsd_setup.log"
+
+# --
+
+typeset -A all_domains=(
+  ["brgen.no"]=("markedsplass" "playlist" "dating" "tv" "takeaway" "maps")
+  ["oshlo.no"]=("markedsplass" "playlist" "dating" "tv" "takeaway" "maps")
+  ["trndheim.no"]=("markedsplass" "playlist" "dating" "tv" "takeaway" "maps")
+  ["stvanger.no"]=("markedsplass" "playlist" "dating" "tv" "takeaway" "maps")
+  ["trmso.no"]=("markedsplass" "playlist" "dating" "tv" "takeaway" "maps")
+  ["longyearbyn.no"]=("markedsplass" "playlist" "dating" "tv" "takeaway" "maps")
+  ["reykjavk.is"]=("markadur" "playlist" "dating" "tv" "takeaway" "maps")
+  ["kobenhvn.dk"]=("markedsplads" "playlist" "dating" "tv" "takeaway" "maps")
+  ["stholm.se"]=("marknadsplats" "playlist" "dating" "tv" "takeaway" "maps")
+  ["mlmoe.se"]=("marknadsplats" "playlist" "dating" "tv" "takeaway" "maps")
+  ["hlsinki.fi"]=("markkinapaikka" "playlist" "dating" "tv" "takeaway" "maps")
+  ["lndon.uk"]=("marketplace" "playlist" "dating" "tv" "takeaway" "maps")
+  ["mnchester.uk"]=("marketplace" "playlist" "dating" "tv" "takeaway" "maps")
+  ["pub.healthcare"]=""
+  ["pub.attorney"]=""
+  ["freehelp.legal"]=""
+  ["bsdports.org"]=""
+  ["discordb.org"]=""
+  ["foodielicio.us"]=""
+  ["sortmyshit.com"]=""
+  ["neurotica.fashion"]=""
+)
+
+# Shared Functions
+log_message() {
+  local level="${1:-INFO}"
+  local message="$2"
+  echo "$(date +%Y-%m-%dT%H:%M:%S) [$level] $message" | tee -a "$LOG_FILE"
+}
+
+retry_command() {
+  local retries=3
+  local delay=5
+  while (( retries > 0 )); do
+    "$@" && return 0
+    log_message "WARN" "Command failed: $@. Retrying... ($retries attempts left)"
+    ((retries--))
+    sleep $delay
+  done
+  log_message "ERROR" "Command failed after multiple attempts: $@. Exiting."
+  exit 1
+}
+
+# Install Necessary Packages
+log_message "INFO" "Installing necessary packages..."
+packages=(ruby-3.3.5 postgresql-server dnscrypt-proxy redis varnish)
+
+for package in "${packages[@]}"; do
+  if ! pkg_info | grep -q "$package"; then
+    retry_command doas pkg_add "$package"
+    if [[ $? -ne 0 ]]; then
+      log_message "ERROR" "Failed to install package: $package"
+      exit 1
+    fi
+  else
+    log_message "INFO" "Package $package is already installed."
+  fi
+  retry_command pkg_info "$package"
+  log_message "DEBUG" "Package $package verified successfully."
+done
+log_message "INFO" "All packages verified."
+
+# Configure pf with improved SSH rules
+log_message "INFO" "Configuring pf..."
+tmp_pf_conf=$(mktemp)
+if [[ $? -ne 0 ]]; then
+  log_message "ERROR" "Failed to create temporary file for pf configuration."
+  exit 1
+fi
+
+log_message "DEBUG" "Writing pf configuration to temporary file $tmp_pf_conf."
+cat << EOF > "$tmp_pf_conf"
+ext_if = "$EXT_IF"
+
+# Allow all loopback traffic
+set skip on lo
+
+# Block stateless traffic and return RSTs
+block return
+
+# Default pass rule to keep state
+pass
+
+# Block all incoming traffic by default and log
+block in log
+
+# Allow all outgoing traffic by default
+pass out quick
+
+# Block brute-force attackers
+table <bruteforce> persist
+block quick from <bruteforce>
+
+# Rate-limit SSH for other IPs
+pass in on $EXT_IF inet proto tcp from any to $EXT_IF port 22 keep state (max-src-conn 15, max-src-conn-rate 5/3, overload <bruteforce> flush global)
+
+# Allow DNS requests and zone transfers
+pass in on $EXT_IF inet proto { tcp, udp } from any to $EXT_IF port 53 keep state
+
+# Allow HTTP and HTTPS traffic
+pass in on $EXT_IF inet proto tcp from any to $EXT_IF port { 80, 443 } keep state
+
+# Include relayd rules if installed
+anchor "relayd/*"
+EOF
+
+# Test and load the pf configuration
+log_message "DEBUG" "Testing pf configuration."
+retry_command doas pfctl -n -f "$tmp_pf_conf"
+if [[ $? -ne 0 ]]; then
+  log_message "ERROR" "pfctl test failed for pf configuration. Please check the configuration."
+  cat "$tmp_pf_conf"
+  exit 1
+fi
+
+# Copy the configuration file if the test passes
+retry_command doas cp "$tmp_pf_conf" /etc/pf.conf
+if [[ $? -ne 0 ]]; then
+  log_message "ERROR" "Failed to copy pf.conf to /etc/. Check permissions."
+  exit 1
+fi
+
+# Clean up temporary file
+if [[ -f "$tmp_pf_conf" ]]; then
+  rm "$tmp_pf_conf"
+  if [[ $? -ne 0 ]]; then
+    log_message "WARN" "Failed to delete temporary file $tmp_pf_conf. Manual cleanup might be required."
+  fi
+fi
+
+# Load pf configuration
+log_message "DEBUG" "Loading pf configuration."
+retry_command doas pfctl -f /etc/pf.conf
+if [[ $? -ne 0 ]]; then
+  log_message "ERROR" "Failed to load pf.conf. Check the configuration for errors."
+  exit 1
+fi
+
+# Enable pf if not already enabled
+if ! doas pfctl -s info | grep -q "Status: Enabled"; then
+  retry_command doas pfctl -e
+  if [[ $? -eq 0 ]]; then
+    log_message "INFO" "pf configured and enabled."
+  else
+    log_message "ERROR" "Failed to enable pf. Please check the system logs."
+    exit 1
+  fi
+else
+  log_message "INFO" "pf is already enabled and configured."
+fi
+
+# Enable pf to start at boot after verification
+retry_command doas rcctl enable pf
+if [[ $? -ne 0 ]]; then
+  log_message "ERROR" "Failed to enable pf for startup. Please check rcctl configuration."
+  exit 1
+fi
+
+# Enable and configure other services (relayd, NSD, OpenSMTPD, etc.)
+manage_service() {
+  local service_name="$1"
+  local action="$2"
+  retry_command doas rcctl "$action" "$service_name"
+  if [[ $? -ne 0 ]]; then
+    log_message "ERROR" "Failed to $action $service_name. Please check logs."
+    exit 1
+  fi
+}
+
+# Configuring relayd
+log_message "INFO" "Configuring relayd..."
+tmp_relayd_conf=$(mktemp)
+if [[ $? -ne 0 ]]; then
+  log_message "ERROR" "Failed to create temporary file for relayd configuration."
+  exit 1
+fi
+log_message "DEBUG" "Writing relayd configuration to temporary file $tmp_relayd_conf."
+cat << EOF > "$tmp_relayd_conf"
+log connection
+
+# Define backend table
+table <backend> { 127.0.0.1 }
+
+# Example relay rule for HTTP traffic
+relay "http_relay" {
+  listen on $EXT_IF port 80
+  forward to <backend> port 8080
+  protocol "http" {
+    match request header set "X-Forwarded-For" value "\$REMOTE_ADDR"
+    match request header set "X-Forwarded-Host" value "\$HTTP_HOST"
+    match request header set "X-Forwarded-Proto" value "http"
+  }
+  connection timeout 300
+}
+EOF
+
+# Test relayd configuration before applying
+log_message "DEBUG" "Testing relayd configuration."
+retry_command doas relayd -n -f "$tmp_relayd_conf"
+if [[ $? -ne 0 ]]; then
+  log_message "ERROR" "relayd configuration test failed. Please check the configuration."
+  cat "$tmp_relayd_conf"
+  exit 1
+fi
+
+retry_command doas cp "$tmp_relayd_conf" /etc/relayd.conf
+rm "$tmp_relayd_conf"
+
+manage_service relayd enable
+manage_service relayd start
+
+# Enable OpenSMTPD to start at boot after verifying configuration
+log_message "INFO" "Configuring OpenSMTPD..."
+retry_command doas smtpd -n -f /etc/mail/smtpd.conf
+if [[ $? -ne 0 ]]; then
+  log_message "ERROR" "OpenSMTPD configuration test failed. Please check the configuration."
+  cat /etc/mail/smtpd.conf
+  exit 1
+fi
+
+manage_service smtpd enable
+manage_service smtpd start
+
+# Create rc.d startup scripts for all apps dynamically from domains.conf
+log_message "INFO" "Creating rc.d startup scripts for all apps..."
+for app in "${(@k)all_domains}"; do
+  cat << EOF | doas tee "/etc/rc.d/$app" > /dev/null
+#!/bin/ksh
+#
+# Startup script for $app
+#
+. /etc/rc.subr
+
+name="$app"
+rcvar="\${name}_enable"
+command="/usr/local/bin/$app"
+command_args="start"
+
+load_rc_config \$name
+run_rc_command "\$1"
+EOF
+  retry_command doas chmod +x "/etc/rc.d/$app"
+done
+
+log_message "INFO" "All app startup scripts created."
+
+log_message "INFO" "Setup script completed successfully."
+
+
```

## `README.md`
```
# OpenBSD Setup for Scalable Rails and Secure Email

This script configures OpenBSD 7.7 as a robust, modular platform for Ruby on Rails applications and a single-user email service, embodying the Unix philosophy of doing one thing well to power a focused, secure system for hyperlocal platforms with DNSSEC.

## Setup Instructions

1. **Prerequisites**:
   - OpenBSD 7.7 installed on master (PowerPC Mac Mini) and slave (VM).
   - Directories (`/var/nsd`, `/var/www/acme`, `/var/postgresql/data`, `/var/redis`, `/var/vmail`) have correct ownership/permissions (e.g., `/var/www/acme` as `root:_httpd`, 755).
   - Rails apps (`brgen`, `amber`, `bsdports`) ready to upload to `/home/<app>/<app>` with `Gemfile` and `database.yml`.
   - Unprivileged user `gfuser` with `mutt` installed for email access.
   - Internet connectivity for package installation.
   - Domain (e.g., `brgen.no`) registered with Domeneshop.no, ready for DS records.

2. **Run the Script**:
   ```bash
   doas zsh openbsd.sh
   ```
   - `--resume`: Run after Stage 1 (DNS/certs).
   - `--mail`: Run after Stage 2 (services/apps) for email.
   - `--help`: Show usage.

3. **Stages**:
   - **Stage 1**: Installs `ruby-3.3.5`, `ldns-utils`, `postgresql-server`, `redis`, and `zap` using OpenBSD 7.7’s default `pkg_add`. Configures `ns.brgen.no` (46.23.95.45) as master nameserver with DNSSEC (ECDSAP256SHA256 keys, signed zones), allowing zone transfers to `ns.hyp.net` (194.63.248.53, managed by Domeneshop.no) via TCP 53 and sending NOTIFY via UDP 53, with `pf` permitting TCP/UDP 53 traffic on `ext_if` (vio0). Generates TLSA records for HTTPS services. Issues certificates via Let’s Encrypt. Pauses to let you upload Rails apps (`brgen`, `amber`, `bsdports`) to `/home/<app>/<app>` with `Gemfile` and `database.yml`. Press Enter to proceed, then submit DS records from `/var/nsd/zones/master/*.ds` to Domeneshop.no. Test with `dig @46.23.95.45 brgen.no SOA`, `dig @46.23.95.45 denvr.us A`, `dig DS brgen.no +short`, and `dig TLSA _443._tcp.brgen.no`. Wait for propagation (24–48 hours) before `--resume`. `ns.hyp.net` requires no local setup (configure slave separately).
   - **Stage 2**: Sets up PostgreSQL, Redis, PF firewall, relayd with security headers, and Rails apps with Falcon server. Logs go to `/var/log/messages`. Applies CSS micro-text (e.g., 7.5pt) for app footer branding if applicable.
   - **Stage 3**: Configures OpenSMTPD for `bergen@pub.attorney`, accessible via `mutt` for `gfuser`.

4. **Verification**:
   - Services: `rcctl check nsd httpd postgresql redis relayd smtpd`.
   - DNS: `dig @46.23.95.45 brgen.no SOA`, `dig @46.23.95.45 denvr.us A`.
   - DNSSEC: `dig DS brgen.no +short`, `dig DNSKEY brgen.no +short`.
   - TLSA: `dig TLSA _443._tcp.brgen.no`.
   - Firewall: `doas pfctl -s rules` to confirm DNS and other rules.
   - Email: Check `/var/vmail/pub.attorney/bergen/new` as `gfuser` with `mutt`.
   - Logs: `tail -f /var/log/messages` for Rails app activity.
```

## `openbsd.sh`
```
#!/usr/bin/env zsh
# OpenBSD Setup for Scalable Rails and Secure Email
# Configures OpenBSD 7.7 as a robust, modular platform for Ruby on Rails applications
# and a single-user email service, with DNSSEC for hyperlocal platforms.
#
# Prerequisites:
# - OpenBSD 7.7 installed on master (PowerPC Mac Mini) and slave (VM).
# - Directories: /var/nsd, /var/www/acme (root:_httpd, 755), /var/postgresql/data,
#   /var/redis, /var/vmail with correct ownership/permissions.
# - Rails apps (brgen, amber, bsdports) ready in /home/<app>/<app> with Gemfile and database.yml.
# - Unprivileged user gfuser with mutt installed for email access.
# - Internet connectivity for package installation.
# - Domain (e.g., brgen.no) registered with Domeneshop.no, ready for DS records.
#
# Usage: doas zsh openbsd.sh [--help | --resume | --mail]
#   --help: Show usage.
#   --resume: Run after Stage 1 (DNS/certs).
#   --mail: Run after Stage 2 (services/apps) for email.
#
# Stages:
# 1. DNS/Certs: Installs ruby-3.3.5, ldns-utils, postgresql-server, redis, zap.
#    Configures ns.brgen.no (46.23.95.45) as master nameserver with DNSSEC,
#    allows zone transfers to ns.hyp.net (194.63.248.53) via TCP 53, sends NOTIFY
#    via UDP 53, PF permits TCP/UDP 53 on ext_if (vio0). Generates TLSA records.
#    Issues Let’s Encrypt certificates. Pauses for app upload and DS record submission.
#    Test with 'dig @46.23.95.45 brgen.no SOA', 'dig @46.23.95.45 denvr.us A',
#    'dig DS brgen.no +short', 'dig TLSA _443._tcp.brgen.no'.
#    Wait 24–48 hours for propagation before --resume.
# 2. Services/Apps: Sets up PostgreSQL, Redis, PF, relayd, Rails apps with Falcon.
#    Logs to /var/log/messages.
# 3. Email: Configures OpenSMTPD for bergen@pub.attorney, accessible via mutt for gfuser.
#
# Verification:
# - Services: rcctl check nsd httpd postgresql redis relayd smtpd.
# - DNS: dig @46.23.95.45 brgen.no SOA, dig @46.23.95.45 denvr.us A.
# - DNSSEC: dig DS brgen.no +short, dig DNSKEY brgen.no +short.
# - TLSA: dig TLSA _443._tcp.brgen.no.
# - Firewall: doas pfctl -s rules.
# - Email: Check /var/vmail/pub.attorney/bergen/new as gfuser with mutt.
# - Logs: tail -f /var/log/messages.

set -e

# Config variables
BRGEN_IP="46.23.95.45"            # Primary IP (ns.brgen.no)
HYP_IP="194.63.248.53"            # Secondary NS (ns.hyp.net)
STATE_FILE="./openbsd_setup_state"
VMAIL_PASS_FILE="/etc/mail/vmail_pass"
UNPRIV_USER="gfuser"              # Local unprivileged user for email access
EMAIL_ADDRESS="bergen@pub.attorney"  # Email address for gfuser
typeset -A APP_PORTS              # App ports
typeset -A FAILED_CERTS           # Failed certs

# Apps for relayd and rc.d
ALL_APPS=(
  "brgen:brgen.no"
  "amber:amberapp.com"
  "bsdports:bsdports.org"
)

# Domains for DNS (restored from commit cfc5b683e67bb624b18fe0ed607031c1661e534f)
ALL_DOMAINS=(
  "brgen.no:markedsplass,playlist,dating,tv,takeaway,maps"
  "longyearbyn.no:markedsplass,playlist,dating,tv,takeaway,maps"
  "oshlo.no:markedsplass,playlist,dating,tv,takeaway,maps"
  "stvanger.no:markedsplass,playlist,dating,tv,takeaway,maps"
  "trmso.no:markedsplass,playlist,dating,tv,takeaway,maps"
  "trndheim.no:markedsplass,playlist,dating,tv,takeaway,maps"
  "reykjavk.is:markadur,playlist,dating,tv,takeaway,maps"
  "kbenhvn.dk:markedsplads,playlist,dating,tv,takeaway,maps"
  "gtebrg.se:marknadsplats,playlist,dating,tv,takeaway,maps"
  "mlmoe.se:marknadsplats,playlist,dating,tv,takeaway,maps"
  "stholm.se:marknadsplats,playlist,dating,tv,takeaway,maps"
  "hlsinki.fi:markkinapaikka,playlist,dating,tv,takeaway,maps"
  "brmingham.uk:marketplace,playlist,dating,tv,takeaway,maps"
  "cardff.uk:marketplace,playlist,dating,tv,takeaway,maps"
  "edinbrgh.uk:marketplace,playlist,dating,tv,takeaway,maps"
  "glasgw.uk:marketplace,playlist,dating,tv,takeaway,maps"
  "lndon.uk:marketplace,playlist,dating,tv,takeaway,maps"
  "lverpool.uk:marketplace,playlist,dating,tv,takeaway,maps"
  "mnchester.uk:marketplace,playlist,dating,tv,takeaway,maps"
  "amstrdam.nl:marktplaats,playlist,dating,tv,takeaway,maps"
  "rottrdam.nl:marktplaats,playlist,dating,tv,takeaway,maps"
  "utrcht.nl:marktplaats,playlist,dating,tv,takeaway,maps"
  "brssels.be:marche,playlist,dating,tv,takeaway,maps"
  "zrich.ch:marktplatz,playlist,dating,tv,takeaway,maps"
  "lchtenstein.li:marktplatz,playlist,dating,tv,takeaway,maps"
  "frankfrt.de:marktplatz,playlist,dating,tv,takeaway,maps"
  "brdeaux.fr:marche,playlist,dating,tv,takeaway,maps"
  "mrseille.fr:marche,playlist,dating,tv,takeaway,maps"
  "mlan.it:mercato,playlist,dating,tv,takeaway,maps"
  "lisbon.pt:mercado,playlist,dating,tv,takeaway,maps"
  "wrsawa.pl:marktplatz,playlist,dating,tv,takeaway,maps"
  "gdnsk.pl:marktplatz,playlist,dating,tv,takeaway,maps"
  "austn.us:marketplace,playlist,dating,tv,takeaway,maps"
  "chcago.us:marketplace,playlist,dating,tv,takeaway,maps"
  "denvr.us:marketplace,playlist,dating,tv,takeaway,maps"
  "dllas.us:marketplace,playlist,dating,tv,takeaway,maps"
  "dnver.us:marketplace,playlist,dating,tv,takeaway,maps"
  "dtroit.us:marketplace,playlist,dating,tv,takeaway,maps"
  "houstn.us:marketplace,playlist,dating,tv,takeaway,maps"
  "lsangeles.com:marketplace,playlist,dating,tv,takeaway,maps"
  "mnnesota.com:marketplace,playlist,dating,tv,takeaway,maps"
  "newyrk.us:marketplace,playlist,dating,tv,takeaway,maps"
  "prtland.com:marketplace,playlist,dating,tv,takeaway,maps"
  "wshingtondc.com:marketplace,playlist,dating,tv,takeaway,maps"
  "pub.healthcare"
  "pub.attorney"
  "freehelp.legal"
  "bsdports.org"
  "bsddocs.org"
  "discordb.org"
  "privcam.no"
  "foodielicio.us"
  "stacyspassion.com"
  "antibettingblog.com"
  "anticasinoblog.com"
  "antigamblingblog.com"
  "foball.no"
)

# Generate random port (10000–60000)
generate_random_port() {
  local port=$((RANDOM % 50000 + 10000))
  netstat -an | grep -q ":$port " || { echo "$port"; return; }
  generate_random_port
}

# Stop nsd and free port 53
cleanup_nsd() {
  echo "Cleaning nsd(8)"
  local retries=0 max_retries=3
  while (( retries++ < max_retries )); do
    doas rcctl stop nsd 2>/dev/null || echo "WARNING: rcctl stop nsd failed"
    doas timeout 10 zap -f nsd 2>/dev/null || echo "WARNING: zap -f nsd failed"
    sleep 2
    netstat -an -p udp | grep -q "$BRGEN_IP.53" || { echo "Port 53 free"; return; }
    echo "Retry $retries: Port 53 still in use"
  done
  echo "ERROR: Port 53 in use after $max_retries retries"
  exit 1
}

# Verify DNS and DNSSEC
verify_dns() {
  echo "Verifying DNS and DNSSEC"
  local domain_entry domain dig_output
  for domain_entry in "${ALL_DOMAINS[@]}"; do
    domain="${domain_entry%%:*}"
    dig_output=$(dig @"$BRGEN_IP" "$domain" A +short)
    [[ "$dig_output" != "$BRGEN_IP" ]] && { echo "ERROR: nsd(8) not authoritative for $domain"; exit 1; }
    dig_output=$(dig @"$BRGEN_IP" "$domain" DNSKEY +short)
    [[ -z "$dig_output" ]] && { echo "ERROR: DNSSEC not enabled for $domain"; exit 1; }
  done
}

# Check DNS propagation
check_dns_propagation() {
  echo "Checking DNS propagation"
  local dig_output
  dig_output=$(dig @8.8.8.8 brgen.no SOA +short)
  [[ -n "$dig_output" && "$dig_output" =~ "ns.brgen.no." ]] || { echo "ERROR: DNS propagation incomplete"; exit 1; }
}

# Generate TLSA record for DANE
generate_tlsa_record() {
  local domain="$1" cert="/etc/ssl/$domain.fullchain.pem"
  [[ ! -f "$cert" ]] && { echo "WARNING: Certificate for $domain not found"; return; }
  local tlsa=$(openssl x509 -noout -pubkey -in "$cert" | openssl pkey -pubin -outform der 2>/dev/null | sha256sum | cut -d' ' -f1)
  echo "_443._tcp.$domain. IN TLSA 3 1 1 $tlsa" >> "/var/nsd/zones/master/$domain.zone"
  sign_zone "$domain"
}

# Sign zone with DNSSEC
sign_zone() {
  local domain="$1" zonefile="/var/nsd/zones/master/$domain.zone" signed_zonefile="/var/nsd/zones/master/$domain.zone.signed"
  local zsk="/var/nsd/zones/master/K$domain.+013+zsk.key" ksk="/var/nsd/zones/master/K$domain.+013+ksk.key"
  [[ ! -f "$zsk" || ! -f "$ksk" ]] && { echo "ERROR: ZSK or KSK missing for $domain"; exit 1; }
  doas ldns-signzone -n -p -s $(head -c 16 /dev/random | sha1) "$zonefile" "$zsk" "$ksk"
  doas nsd-checkzone "$domain" "$signed_zonefile" || { echo "ERROR: Signed zone file for $domain invalid"; exit 1; }
}

# Install required packages
install_packages() {
  echo "Installing required packages"
  doas pkg_add -U ruby-3.3.5 ldns-utils postgresql-server redis zap sshguard || {
    echo "ERROR: Package installation failed; check uname -r (7.7)"
    exit 1
  }
}

# Configure minimal PF
configure_pf() {
  echo "Configuring minimal PF"
  cat > "/etc/pf.conf" <<EOF
ext_if="vio0"
set skip on lo
block return
pass
block in log
pass out quick
table <bruteforce> persist
block quick from <bruteforce>
pass in on \$ext_if inet proto { tcp, udp } to $BRGEN_IP port 53 keep state
pass out on \$ext_if inet proto udp to $HYP_IP port 53
EOF
  doas pfctl -nf "/etc/pf.conf" || { echo "ERROR: pf.conf invalid"; exit 1; }
  doas pfctl -f "/etc/pf.conf" || { echo "ERROR: pf(4) failed"; exit 1; }
}

# Configure NSD with DNSSEC
configure_dns_dnssec() {
  echo "Configuring NSD with DNSSEC"
  doas rm -rf /var/nsd/etc/* /var/nsd/zones/master/*
  cat > "/var/nsd/etc/nsd.conf" <<EOF
server:
  ip-address: $BRGEN_IP
  hide-version: yes
  zonesdir: "/var/nsd/zones/master"
remote-control:
  control-enable: yes
EOF
  local domain_entry domain
  for domain_entry in "${ALL_DOMAINS[@]}"; do
    domain="${domain_entry%%:*}"
    cat >> "/var/nsd/etc/nsd.conf" <<EOF
zone:
  name: "$domain"
  zonefile: "$domain.zone.signed"
  provide-xfr: $HYP_IP NOKEY
  notify: $HYP_IP NOKEY
EOF
  done
  doas nsd-checkconf /var/nsd/etc/nsd.conf || { echo "ERROR: nsd.conf invalid"; exit 1; }
  local serial=$(date +"%Y%m%d%H") domain_entry domain subdomains subdomain
  for domain_entry in "${ALL_DOMAINS[@]}"; do
    domain="${domain_entry%%:*}" subdomains="${domain_entry#*:}"
    cat > "/var/nsd/zones/master/$domain.zone" <<EOF
\$ORIGIN $domain.
\$TTL 3600
@ IN SOA ns.brgen.no. hostmaster.$domain. ( $serial 1800 900 604800 86400 )
@ IN NS ns.brgen.no.
@ IN NS ns.hyp.net.
@ IN A $BRGEN_IP
@ IN MX 10 mail.$domain.
@ IN CAA 0 issue "letsencrypt.org"
mail IN A $BRGEN_IP
EOF
    [[ "$domain" = "brgen.no" ]] && echo "ns IN A $BRGEN_IP" >> "/var/nsd/zones/master/$domain.zone"
    [[ -n "$subdomains" && "$subdomains" != "$domain" ]] && for subdomain in ${(s/,/)subdomains}; do
      echo "$subdomain IN A $BRGEN_IP" >> "/var/nsd/zones/master/$domain.zone"
    done
    doas ldns-keygen -a ECDSAP256SHA256 -b 1024 "$domain" >/dev/null
    doas ldns-keygen -k -a ECDSAP256SHA256 -b 2048 "$domain" >/dev/null
    doas mv K$domain.* /var/nsd/zones/master/
    sign_zone "$domain"
    doas ldns-key2ds -n -2 "/var/nsd/zones/master/$domain.zone.signed" > "/var/nsd/zones/master/$domain.ds"
  done
  cleanup_nsd
  doas rcctl enable nsd
  doas timeout 10 rcctl start nsd || { echo "ERROR: nsd(8) failed to start"; exit 1; }
  sleep 5
  doas rcctl check nsd | grep -q "nsd(ok)" || { echo "ERROR: nsd(8) not running"; exit 1; }
}

# Configure httpd for ACME
configure_httpd() {
  echo "Configuring httpd for ACME"
  doas mkdir -p /var/www/acme
  doas chown root:_httpd /var/www/acme
  doas chmod 755 /var/www/acme
  cat > "/etc/httpd.conf" <<EOF
server "acme" {
  listen on $BRGEN_IP port 80
  location "/.well-known/acme-challenge/*" {
    root "/acme"
    request strip 2
  }
  location "*" {
    block return 301 "https://\$HTTP_HOST\$REQUEST_URI"
  }
}
EOF
  doas httpd -n -f "/etc/httpd.conf" || { echo "ERROR: httpd.conf invalid"; exit 1; }
  doas rcctl enable httpd
  doas rcctl start httpd || { echo "ERROR: httpd(8) failed"; exit 1; }
  sleep 5
  doas rcctl check httpd | grep -q "httpd(ok)" || { echo "ERROR: httpd(8) not running"; exit 1; }
}

# Verify httpd
verify_httpd() {
  echo "Verifying httpd"
  doas echo "test" > "/var/www/acme/.well-known/acme-challenge/test"
  local status=$(curl -s -o /dev/null -w "%{http_code}" "http://brgen.no/.well-known/acme-challenge/test")
  doas rm "/var/www/acme/.well-known/acme-challenge/test"
  [[ "$status" != "200" ]] && { echo "ERROR: httpd pre-flight failed"; exit 1; }
}

# Configure ACME client
configure_acme() {
  echo "Configuring ACME client"
  [[ ! -f "/etc/acme/letsencrypt_privkey.pem" ]] && doas openssl genpkey -algorithm RSA -out "/etc/acme/letsencrypt_privkey.pem" -pkeyopt rsa_keygen_bits:4096
  cat > "/etc/acme-client.conf" <<'EOF'
authority letsencrypt {
  api url "https://acme-v02.api.letsencrypt.org/directory"
  account key "/etc/acme/letsencrypt_privkey.pem"
}
EOF
  local domain_entry domain subdomains subdomain
  for domain_entry in "${ALL_DOMAINS[@]}"; do
    domain="${domain_entry%%:*}" subdomains="${domain_entry#*:}"
    [[ -n "$subdomains" && "$subdomains" != "$domain" ]] && subdomains="www ${subdomains//,/ }" || subdomains="www"
    cat >> "/etc/acme-client.conf" <<EOF
domain "$domain" {
  alternative names { $subdomains }
  domain key "/etc/ssl/private/$domain.key"
  domain full chain certificate "/etc/ssl/$domain.fullchain.pem"
  sign with letsencrypt
  challengedir "/var/www/acme"
}
EOF
  done
  doas acme-client -n -f "/etc/acme-client.conf" || { echo "ERROR: acme-client.conf invalid"; exit 1; }
}

# Issue Let’s Encrypt certificates
issue_certs() {
  echo "Issuing Let’s Encrypt certificates"
  local domain_entry domain subdomains subdomain status retries=0
  while (( retries++ < 3 )); do
    for domain_entry in "${ALL_DOMAINS[@]}"; do
      domain="${domain_entry%%:*}" subdomains="${domain_entry#*:}"
      [[ -n "${FAILED_CERTS[$domain]}" ]] && continue
      [[ -n "$subdomains" && "$subdomains" != "$domain" ]] && subdomains="www ${subdomains//,/ }" || subdomains="www"
      for subdomain in $subdomains; do
        local full_domain="$subdomain.$domain"
        [[ "$subdomain" = "www" ]] && full_domain="$domain"
        doas echo "test_$full_domain" > "/var/www/acme/.well-known/acme-challenge/test_$full_domain"
        status=$(curl -s -o /dev/null -w "%{http_code}" "http://$full_domain/.well-known/acme-challenge/test_$full_domain")
        doas rm "/var/www/acme/.well-known/acme-challenge/test_$full_domain"
        [[ "$status" != "200" ]] && { echo "WARNING: HTTP test for $full_domain failed"; FAILED_CERTS[$domain]=1; continue 2; }
      done
      doas acme-client -v -f "/etc/acme-client.conf" "$domain" && generate_tlsa_record "$domain" || FAILED_CERTS[$domain]=1
    done
    (( ${#FAILED_CERTS[@]} == 0 )) && break
    retry_failed_certs
  done
  (( ${#FAILED_CERTS[@]} > 0 )) && { echo "ERROR: Failed to issue certs for ${FAILED_CERTS[@]}"; exit 1; }
}

# Retry failed certificates
retry_failed_certs() {
  echo "Retrying failed certificates"
  local domain subdomains subdomain status
  for domain in ${(k)FAILED_CERTS}; do
    subdomains=""
    for domain_entry in "${ALL_DOMAINS[@]}"; do
      [[ "${domain_entry%%:*}" = "$domain" ]] && subdomains="${domain_entry#*:}"
    done
    [[ -n "$subdomains" && "$subdomains" != "$domain" ]] && subdomains="www ${subdomains//,/ }" || subdomains="www"
    for subdomain in $subdomains; do
      local full_domain="$subdomain.$domain"
      [[ "$subdomain" = "www" ]] && full_domain="$domain"
      doas echo "retry_$full_domain" > "/var/www/acme/.well-known/acme-challenge/retry_$full_domain"
      status=$(curl -s -o /dev/null -w "%{http_code}" "http://$full_domain/.well-known/acme-challenge/retry_$full_domain")
      doas rm "/var/www/acme/.well-known/acme-challenge/retry_$full_domain"
      [[ "$status" != "200" ]] && { echo "WARNING: Retry HTTP for $full_domain failed"; continue 2; }
    done
    doas acme-client -v -f "/etc/acme-client.conf" "$domain" && { unset FAILED_CERTS[$domain]; generate_tlsa_record "$domain"; }
  done
}

# Schedule certificate renewal
schedule_renewal() {
  echo "Scheduling certificate renewal"
  local crontab_tmp="/tmp/crontab_tmp"
  crontab -l 2>/dev/null > "$crontab_tmp" || true
  echo "0 2 * * 1 for domain in ${ALL_DOMAINS[*]%%:*}; do doas acme-client -v -f /etc/acme-client.conf \$domain && doas rcctl reload relayd && generate_tlsa_record \$domain; done" >> "$crontab_tmp"
  doas crontab "$crontab_tmp"
  rm "$crontab_tmp"
}

# Configure full PF
configure_pf_full() {
  echo "Configuring full PF"
  cat > "/etc/pf.conf" <<EOF
ext_if="vio0"
set skip on lo
set optimization aggressive
block return
pass
block in log
pass out quick
table <bruteforce> persist
block quick from <bruteforce>
pass in on \$ext_if inet proto tcp to \$ext_if port 22 keep state (max-src-conn 50, max-src-conn-rate 20/60, overload <bruteforce> flush global)
pass in on \$ext_if inet proto { tcp, udp } to $BRGEN_IP port 53 keep state
pass in on \$ext_if inet proto tcp to $BRGEN_IP port { 80, 443, 25, 587 } keep state
anchor "relayd/*"
EOF
  doas pfctl -nf "/etc/pf.conf" || { echo "ERROR: pf.conf invalid"; exit 1; }
  doas pfctl -f "/etc/pf.conf" || { echo "ERROR: pf(4) failed"; exit 1; }
}

# Configure SSHguard
configure_sshguard() {
  echo "Configuring SSHguard"
  doas rcctl enable sshguard
  doas rcctl start sshguard || { echo "ERROR: sshguard failed"; exit 1; }
  sleep 5
  doas rcctl check sshguard | grep -q "sshguard(ok)" || { echo "ERROR: sshguard not running"; exit 1; }
}

# Set up PostgreSQL
configure_postgresql() {
  echo "Configuring PostgreSQL"
  [[ ! -d "/var/postgresql/data" ]] && {
    doas install -d -o _postgresql -g _postgresql "/var/postgresql/data"
    doas su -l _postgresql -c "/usr/local/bin/initdb -D /var/postgresql/data -U postgres -A scram-sha-256 -E UTF8"
  }
  doas rcctl enable postgresql
  doas rcctl start postgresql || { echo "ERROR: postgresql(8) failed"; exit 1; }
  sleep 5
  doas rcctl check postgresql | grep -q "postgresql(ok)" || { echo "ERROR: postgresql(8) not running"; exit 1; }
}

# Set up Redis
configure_redis() {
  echo "Configuring Redis"
  cat > "/etc/redis.conf" <<EOF
bind 127.0.0.1
port 6379
protected-mode yes
daemonize yes
dir /var/redis
EOF
  doas redis-server --dry-run "/etc/redis.conf" || { echo "ERROR: redis.conf invalid"; exit 1; }
  doas rcctl enable redis
  doas rcctl start redis || { echo "ERROR: redis(1) failed"; exit 1; }
  sleep 5
  doas rcctl check redis | grep -q "redis(ok)" || { echo "ERROR: redis(1) not running"; exit 1; }
}

# Configure relayd for HTTPS/WebSocket proxy
configure_relayd() {
  echo "Configuring relayd"
  cat > "/etc/relayd.conf" <<EOF
log connection
table <acme_client> { 127.0.0.1:80 }
http protocol "filter_challenge" {
  pass request path "/.well-known/acme-challenge/*" forward to <acme_client>
  http websockets
}
relay "http_relay" {
  listen on $BRGEN_IP port 80
  protocol "filter_challenge"
  forward to <acme_client> port 80
}
http protocol "secure_rails" {
  match request header set "X-Forwarded-For" value "\$REMOTE_ADDR"
  match response header set "Cache-Control" value "max-age=1814400"
  match response header set "Content-Security-Policy" value "upgrade-insecure-requests; default-src https: 'self'"
  match response header set "Strict-Transport-Security" value "max-age=31536000; includeSubDomains; preload"
  match response header set "Referrer-Policy" value "strict-origin"
  match response header set "Feature-Policy" value "accelerometer 'none'; camera 'none'; geolocation 'none'; gyroscope 'none'; magnetometer 'none'; microphone 'none'; payment 'none'; usb 'none'"
  match response header set "X-Content-Type-Options" value "nosniff"
  match response header set "X-Download-Options" value "noopen"
  match response header set "X-Frame-Options" value "SAMEORIGIN"
  match response header set "X-Robots-Tag" value "index, nofollow"
  match response header set "X-XSS-Protection" value "1; mode=block"
  http websockets
}
EOF
  local app_entry app port
  for app_entry in "${ALL_APPS[@]}"; do
    app="${app_entry%%:*}" port="${APP_PORTS[$app]:=$(generate_random_port)}"
    APP_PORTS[$app]=$port
    cat >> "/etc/relayd.conf" <<EOF
table <${app}_backend> { 127.0.0.1:$port }
relay "relay_${app}" {
  listen on $BRGEN_IP port 443 tls
  protocol "secure_rails"
  forward to <${app}_backend> port $port
}
EOF
  done
  doas relayd -n -f "/etc/relayd.conf" || { echo "ERROR: relayd.conf invalid"; exit 1; }
  doas rcctl enable relayd
  doas rcctl start relayd || { echo "ERROR: relayd(8) failed"; exit 1; }
  sleep 5
  doas rcctl check relayd | grep -q "relayd(ok)" || { echo "ERROR: relayd(8) not running"; exit 1; }
}

# Configure OpenSMTPD for email relaying
configure_smtpd() {
  echo "Configuring OpenSMTPD"
  local email_domain="pub.attorney" email_user="bergen"
  doas mkdir -p "/var/vmail/$email_domain/$email_user/{cur,new,tmp}"
  doas chown -R "$UNPRIV_USER:$UNPRIV_USER" "/var/vmail/$email_domain/$email_user"
  doas chmod -R 700 "/var/vmail/$email_domain/$email_user"
  cat > "/etc/mail/smtpd.conf" <<EOF
listen on $BRGEN_IP port 25
listen on $BRGEN_IP port 587 tls-require auth <secrets> tag submission
table vdomains { pub.attorney }
table aliases { bergen: /var/vmail/pub.attorney/bergen }
table secrets file:/etc/mail/secrets
accept from any for domain <vdomains> alias <aliases> deliver to maildir "/var/vmail/%{dest.domain}/%{dest.user}"
accept tagged submission for any destination relay
EOF
  cat > "/etc/mail/aliases" <<'EOF'
bergen: /var/vmail/pub.attorney/bergen
EOF
  doas newaliases
  [[ ! -f "/etc/mail/secrets" ]] && {
    local vmail_password=$(openssl rand -base64 24)
    doas echo "$vmail_password" > "$VMAIL_PASS_FILE"
    doas chmod 640 "$VMAIL_PASS_FILE"
    doas echo "bergen:$vmail_password" | doas smtpctl encrypt > "/etc/mail/secrets"
    doas chmod 640 "/etc/mail/secrets"
  }
  [[ ! -f "/etc/mail/smtpd.key" ]] && {
    doas openssl req -x509 -newkey rsa:4096 -nodes -keyout "/etc/mail/smtpd.key" -out "/etc/mail/smtpd.crt" -days 365 -subj "/C=US/ST=CA/L=San Francisco/O=PubAttorney/CN=mail.pub.attorney"
    doas chmod 640 "/etc/mail/smtpd.key" "/etc/mail/smtpd.crt"
  }
  local muttrc="/home/$UNPRIV_USER/.muttrc"
  cat > "$muttrc" <<EOF
set mbox_type=Maildir
set folder=/var/vmail/pub.attorney/bergen
set spoolfile=/var/vmail/pub.attorney/bergen/new
set smtp_url="smtp://$EMAIL_ADDRESS@mail.$email_domain:587"
set smtp_pass="$(cat $VMAIL_PASS_FILE)"
set from="$EMAIL_ADDRESS"
set realname="Bergen"
EOF
  doas chown "$UNPRIV_USER:$UNPRIV_USER" "$muttrc"
  doas chmod 600 "$muttrc"
  doas smtpdctl show config || { echo "ERROR: smtpd.conf invalid"; exit 1; }
  doas rcctl enable smtpd
  doas rcctl start smtpd || { echo "ERROR: smtpd(8) failed"; exit 1; }
  sleep 5
  doas rcctl check smtpd | grep -q "smtpd(ok)" || { echo "ERROR: smtpd(8) not running"; exit 1; }
  echo "Test email" | mail -s "Test Email" "$EMAIL_ADDRESS"
  sleep 1
  ls /var/vmail/pub.attorney/bergen/new/* >/dev/null 2>&1 || echo "WARNING: Test email to $EMAIL_ADDRESS failed"
}

# Generate rc.d scripts for apps
generate_rcd_scripts() {
  echo "Generating rc.d scripts"
  local app_entry app port app_dir
  for app_entry in "${ALL_APPS[@]}"; do
    app="${app_entry%%:*}" port="${APP_PORTS[$app]:=$(generate_random_port)}"
    APP_PORTS[$app]=$port
    app_dir="/home/_${app}/${app}"
    [[ ! -d "$app_dir" || ! -f "$app_dir/Gemfile" || ! -f "$app_dir/config/database.yml" ]] && {
      echo "ERROR: App directory $app_dir, Gemfile, or database.yml missing"
      exit 1
    }
    doas useradd -m -s /bin/ksh -L rails "_${app}" || echo "User _${app} already exists"
    doas chown -R "_${app}:_${app}" "/home/_${app}"
    su - "_${app}" -c "gem install --user-install rails bundler"
    su - "_${app}" -c "cd $app_dir && bundle add falcon --skip-install && bundle install"
    cat > "/etc/rc.d/$app" <<EOF
#!/bin/ksh
daemon="/home/_${app}/${app}/bin/falcon-host"
daemon_user="_${app}"
daemon_flags="--port $port"
unveil /home/_${app}/${app} r
unveil /var/log w
unveil /etc/ssl r
pledge stdio rpath wpath cpath inet
. /etc/rc.d/rc.subr
rc_cmd \$1
EOF
    doas chmod +x "/etc/rc.d/$app"
    doas rcctl enable "$app" || { echo "ERROR: rcctl enable $app failed"; exit 1; }
    doas rcctl start "$app" || { echo "ERROR: $app failed to start"; exit 1; }
    sleep 5
    doas rcctl check "$app" | grep -q "$app(ok)" || { echo "ERROR: $app not running"; exit 1; }
  done
}

# Run health checks
run_health_checks() {
  echo "Running health checks"
  local services=(nsd httpd postgresql redis relayd smtpd sshguard)
  for service in $services; do
    doas rcctl check $service | grep -q "$service(ok)" || {
      echo "ERROR: $service not running"
      exit 1
    }
  done
  for app_entry in "${ALL_APPS[@]}"; do
    local app="${app_entry%%:*}"
    doas rcctl check $app | grep -q "$app(ok)" || echo "WARNING: $app not running"
  done
  local dig_output=$(dig @"$BRGEN_IP" brgen.no SOA +short)
  [[ -z "$dig_output" ]] && { echo "ERROR: DNS for brgen.no failed"; exit 1; }
  local http_status=$(curl -s -o /dev/null -w "%{http_code}" http://brgen.no/.well-known/acme-challenge/test 2>/dev/null || echo "404")
  [[ "$http_status" != "404" ]] && echo "WARNING: HTTP check failed"
  local smtp_status=$(timeout 5 telnet mail.brgen.no 587 2>&1 | grep -c "220")
  [[ $smtp_status -eq 0 ]] && echo "WARNING: SMTP check failed"
  echo "Health checks completed"
}

# Stage 1: DNS and Certificates
stage_1() {
  echo "Starting Stage 1: DNS and Certificates"
  [[ -f "/etc/rc.conf.local" && $(grep "pf=NO" /etc/rc.conf.local) ]] && echo "WARNING: pf disabled"
  doas pfctl -s info | grep -q "Status: Enabled" || doas pfctl -e || { echo "ERROR: Failed to enable pf(4)"; exit 1; }
  install_packages
  configure_pf
  configure_dns_dnssec
  verify_dns
  configure_httpd
  verify_httpd
  configure_acme
  issue_certs
  schedule_renewal
  echo "Please upload Rails apps (brgen, amber, bsdports) to their respective homedirs (/home/_<app>/<app>), ensuring each has Gemfile and config/database.yml. Press Enter to continue once complete."
  read -r
  echo "stage_1_complete" > "$STATE_FILE"
  echo "Stage 1 complete. Submit DS records from /var/nsd/zones/master/*.ds to Domeneshop.no. Test with 'dig @46.23.95.45 brgen.no SOA', 'dig @46.23.95.45 denvr.us A', 'dig DS brgen.no +short', 'dig TLSA _443._tcp.brgen.no'. Wait 24–48 hours for propagation before running 'doas zsh openbsd.sh --resume'."
  exit 0
}

# Stage 2: Services and Relay
stage_2() {
  echo "Starting Stage 2: Services and Apps"
  check_dns_propagation
  configure_pf_full
  configure_postgresql
  configure_redis
  configure_relayd
  generate_rcd_scripts
  configure_sshguard
  run_health_checks
  echo "stage_2_complete" > "$STATE_FILE"
  echo "Stage 2 complete. Run 'doas zsh openbsd.sh --mail' to set up email."
  exit 0
}

# Stage 3: Email Setup
stage_3() {
  echo "Starting Stage 3: Email Setup"
  configure_smtpd
  run_health_checks
  rm -f "$STATE_FILE"
  echo "Setup complete."
  exit 0
}

# Main execution
main() {
  [[ "$1" = "--help" ]] && { echo "Sets up OpenBSD 7.7 for Rails and email with DNSSEC."; exit 0; }
  [[ "$1" = "--mail" ]] && { [[ -f "$STATE_FILE" && $(grep "stage_2_complete" "$STATE_FILE") ]] || { echo "ERROR: Stage 2 not complete"; exit 1; }; stage_3; }
  [[ "$1" = "--resume" || $(grep "stage_1_complete" "$STATE_FILE" 2>/dev/null) ]] && stage_2 || stage_1
}

main "$@"

# EOF: Line count and checksum generated by master.jso
```

