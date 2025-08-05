#!/usr/bin/env zsh

# OpenBSD 7.8+ setup for multiple Rails apps with DNSSEC, enhanced security,
# PostgreSQL, and structured port mapping
# Merges PR #144 improvements with DNSSEC implementation

set -e
set -x

main_ip="46.23.95.45"
hyp_ip="194.63.248.53"

# Logging and state management
LOG_FILE="./openbsd_setup.log"

# JSON logging function
log() {
    local message="$1"
    printf '{"timestamp":"%s","level":"INFO","message":"%s"}\n' \
        "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$message" >> "$LOG_FILE"
    echo "$message"
}

# Error handling function
run_cmd() {
    if ! eval "$@"; then
        log "Error: Command failed: $*"
        exit 1
    fi
}

# Define all domains, subdomains and associated apps
typeset -A all_domains
all_domains[brgen.no]="markedsplass playlist dating tv takeaway maps"
all_domains[oshlo.no]="markedsplass playlist dating tv takeaway maps"
all_domains[trndheim.no]="markedsplass playlist dating tv takeaway maps"
all_domains[stvanger.no]="markedsplass playlist dating tv takeaway maps"
all_domains[trmso.no]="markedsplass playlist dating tv takeaway maps"
all_domains[longyearbyn.no]="markedsplass playlist dating tv takeaway maps"
all_domains[reykjavk.is]="markadur playlist dating tv takeaway maps"
all_domains[kobenhvn.dk]="markedsplads playlist dating tv takeaway maps"
all_domains[stholm.se]="marknadsplats playlist dating tv takeaway maps"
all_domains[gteborg.se]="marknadsplats playlist dating tv takeaway maps"
all_domains[mlmoe.se]="marknadsplats playlist dating tv takeaway maps"
all_domains[hlsinki.fi]="markkinapaikka playlist dating tv takeaway maps"
all_domains[lndon.uk]="marketplace playlist dating tv takeaway maps"
all_domains[mnchester.uk]="marketplace playlist dating tv takeaway maps"
all_domains[brmingham.uk]="marketplace playlist dating tv takeaway maps"
all_domains[edinbrgh.uk]="marketplace playlist dating tv takeaway maps"
all_domains[glasgw.uk]="marketplace playlist dating tv takeaway maps"
all_domains[lverpool.uk]="marketplace playlist dating tv takeaway maps"
all_domains[amstrdam.nl]="marktplaats playlist dating tv takeaway maps"
all_domains[rottrdam.nl]="marktplaats playlist dating tv takeaway maps"
all_domains[utrcht.nl]="marktplaats playlist dating tv takeaway maps"
all_domains[brssels.be]="marche playlist dating tv takeaway maps"
all_domains[zrich.ch]="marktplatz playlist dating tv takeaway maps"
all_domains[lchtenstein.li]="marktplatz playlist dating tv takeaway maps"
all_domains[frankfrt.de]="marktplatz playlist dating tv takeaway maps"
all_domains[mrseille.fr]="marche playlist dating tv takeaway maps"
all_domains[mlan.it]="mercato playlist dating tv takeaway maps"
all_domains[lsbon.pt]="mercado playlist dating tv takeaway maps"
all_domains[lsangeles.com]="marketplace playlist dating tv takeaway maps"
all_domains[newyrk.us]="marketplace playlist dating tv takeaway maps"
all_domains[chcago.us]="marketplace playlist dating tv takeaway maps"
all_domains[dtroit.us]="marketplace playlist dating tv takeaway maps"
all_domains[houstn.us]="marketplace playlist dating tv takeaway maps"
all_domains[dllas.us]="marketplace playlist dating tv takeaway maps"
all_domains[austn.us]="marketplace playlist dating tv takeaway maps"
all_domains[prtland.com]="marketplace playlist dating tv takeaway maps"
all_domains[mnneapolis.com]="marketplace playlist dating tv takeaway maps"
all_domains[pub.healthcare]=""
all_domains[pub.attorney]=""
all_domains[freehelp.legal]=""
all_domains[bsdports.org]=""
all_domains[discordb.org]=""
all_domains[foodielicio.us]=""
all_domains[neuroticerotic.com]=""

# Fixed port mapping (replacing random port assignment)
typeset -A app_ports
app_ports[brgen]=3000
app_ports[bsdports]=3001
app_ports[neuroticerotic]=3002

# Define apps and their associated domains
typeset -A apps_domains
apps_domains[brgen]="brgen.no"
apps_domains[bsdports]="bsdports.org"
apps_domains[neuroticerotic]="neuroticerotic.com"

# -- INSTALLATION BEGIN --

log "Starting OpenBSD server setup for multiple Rails apps"
log "Installing necessary packages with enhanced features"

# Install comprehensive package set including DNSSEC support
run_cmd "doas pkg_add -U ruby postgresql-server postgresql-client redis node zap ldns-utils dnscrypt-proxy"

# Install falcon for Rails app serving
run_cmd "gem install falcon"

log "Packages installed successfully"

# -- PostgreSQL Setup --

setup_postgresql() {
    log "Setting up PostgreSQL with complete database initialization"
    
    # Initialize PostgreSQL if not already done
    if [ ! -d /var/postgresql/data ]; then
        run_cmd "doas install -d -o _postgresql -g _postgresql /var/postgresql/data"
        run_cmd "doas -u _postgresql initdb -D /var/postgresql/data -U postgres -A scram-sha-256 -E UTF8"
        log "PostgreSQL database cluster initialized"
    fi
    
    # Start PostgreSQL service
    run_cmd "doas rcctl enable postgresql"
    run_cmd "doas rcctl start postgresql"
    
    # Create databases and users for each application
    for app in "${(@k)apps_domains}"; do
        log "Creating database and user for app: $app"
        DB_NAME="${app}_db"
        DB_USER="${app}_user"
        DB_PASS="securepassword$(openssl rand -hex 8)"
        
        # Create database and user
        run_cmd "doas -u _postgresql createdb $DB_NAME" || log "Database $DB_NAME may already exist"
        run_cmd "doas -u _postgresql psql -c \"CREATE USER $DB_USER WITH PASSWORD '$DB_PASS';\"" || log "User $DB_USER may already exist"
        run_cmd "doas -u _postgresql psql -c \"GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;\""
        
        # Save database credentials
        echo "$DB_PASS" | doas tee "/home/$app/.db_pass" > /dev/null
        doas chown "$app:wheel" "/home/$app/.db_pass" 2>/dev/null || true
        doas chmod 600 "/home/$app/.db_pass" 2>/dev/null || true
        
        log "Database setup complete for $app: $DB_NAME"
    done
    
    log "PostgreSQL setup completed"
}

# -- Enhanced PF Firewall with Security Improvements --

log "Setting up enhanced pf.conf with SSH brute-force and DoS protection"
doas tee /etc/pf.conf > /dev/null << "EOF"
ext_if = "vio0"

# Skip filtering on loopback interfaces for performance
set skip on lo

# Table to track brute force attempts - managed with pfctl -t bruteforce -T [show|flush|delete <IP>]
table <bruteforce> persist

# Return RSTs instead of silently dropping for better client behavior
set block-policy return

# Enable logging on external interface for security monitoring
set loginterface $ext_if

# Normalize all incoming traffic to prevent OS fingerprinting
scrub in all

# Block all traffic by default (deny-by-default security model)
block log all

# Allow all outgoing traffic (applications can reach external services)
pass out quick on $ext_if all

# SSH with enhanced brute-force protection
pass in on $ext_if proto tcp to $ext_if port 22 keep state (max-src-conn 2, max-src-conn-rate 2/60, overload <bruteforce> flush global)

# HTTP and HTTPS with DoS protection
pass in on $ext_if proto tcp to $ext_if port { 80, 443 } keep state (max-src-conn 100, max-src-conn-rate 100/60)

# DNS - Allow incoming DNS queries (TCP and UDP for zone transfers and queries)
pass in on $ext_if proto { tcp, udp } to $ext_if port 53 keep state

# ICMP - Allow essential ICMP traffic for network functionality
pass inet proto icmp all icmp-type { echoreq, unreach, timex, paramprob }
EOF

# Load and enable firewall
run_cmd "doas pfctl -f /etc/pf.conf"
run_cmd "doas rcctl enable pf"
log "Enhanced firewall configuration completed"

# -- Enhanced RELAYD with Security Headers --

log "Configuring relayd.conf with enhanced security headers and fixed port mapping"
doas tee /etc/relayd.conf > /dev/null << EOF
egress "$main_ip"
EOF

for app in "${(@k)apps_domains}"; do
  domain=${apps_domains[$app]}
  port=${app_ports[$app]}

  log "Adding relayd configuration for app: $app, domain: $domain, port: $port (fixed)"
  doas tee -a /etc/relayd.conf > /dev/null << EOF

table <${app}> { 127.0.0.1 }

protocol "http_protocol_${app}" {
  match request header set "X-Forwarded-By" value "\$SERVER_ADDR:\$SERVER_PORT"
  match request header set "X-Forwarded-For" value "\$REMOTE_ADDR"
  match request header set "X-Forwarded-Proto" value "https"
  
  # Enhanced Security Headers
  match response header set "Content-Security-Policy" value "upgrade-insecure-requests; default-src https:; style-src 'self' 'unsafe-inline'; font-src 'self' data:; script-src 'self' 'unsafe-inline' 'unsafe-eval'"
  match response header set "Strict-Transport-Security" value "max-age=31536000; includeSubDomains; preload"
  match response header set "Referrer-Policy" value "strict-origin"
  match response header set "X-Content-Type-Options" value "nosniff"
  match response header set "X-Download-Options" value "noopen"
  match response header set "X-Frame-Options" value "DENY"
  match response header set "X-XSS-Protection" value "1; mode=block"
  match response header set "Permissions-Policy" value "accelerometer=(), camera=(), geolocation=(), gyroscope=(), magnetometer=(), microphone=(), payment=(), usb=()"

  tcp { no delay }
  
  # Enhanced timeouts for better performance
  request timeout 20
  session timeout 60

  forward to <${app}> port $port
}

relay "http_${app}" {
  listen on \$egress port 80
  protocol "http_protocol_${app}"
}

relay "https_${app}" {
  listen on \$egress port 443 tls
  protocol "http_protocol_${app}"
}
EOF

done

log "Enabling and starting relayd with enhanced configuration"
run_cmd "doas rcctl enable relayd"
run_cmd "doas rcctl start relayd"

# -- HTTPD with ACME Support --

log "Configuring httpd.conf with ACME challenge support"
doas tee /etc/httpd.conf > /dev/null << EOF
server "default" {
  listen on * port 80
  location "/.well-known/acme-challenge/*" {
    root "/acme"
    request strip 2
  }
}
EOF

log "Creating directory for ACME challenges with proper permissions"
run_cmd "doas mkdir -p /var/www/acme"
run_cmd "doas chown -R www:www /var/www/acme"

log "Setting up acme-client.conf with Let's Encrypt configuration"
doas tee /etc/acme-client.conf > /dev/null << EOF
authority letsencrypt {
  api url "https://acme-v02.api.letsencrypt.org/directory"
  account key "/etc/acme/letsencrypt-privkey.pem"
}

authority letsencrypt-staging {
  api url "https://acme-staging-v02.api.letsencrypt.org/directory"
  account key "/etc/acme/letsencrypt-staging-privkey.pem"
}
EOF

# Add ACME configurations for domains
for domain in "${(@k)all_domains}"; do
  log "Adding ACME configuration for domain: $domain"
  doas tee -a /etc/acme-client.conf > /dev/null << EOF
domain "$domain" {
  domain key "/etc/ssl/private/$domain.key"
  domain fullchain "/etc/ssl/acme/$domain.fullchain"
  domain chain "/etc/ssl/acme/$domain.chain"
  domain cert "/etc/ssl/acme/$domain.crt"
  sign with letsencrypt
}
EOF
done

log "Enabling and starting httpd"
run_cmd "doas rcctl enable httpd"
run_cmd "doas rcctl start httpd"

# -- NSD with DNSSEC Implementation --

log "Setting up NSD with full DNSSEC support using ldns-utils"

log "Creating NSD directories with proper permissions"
run_cmd "doas mkdir -p /var/nsd/zones/master /etc/nsd"
run_cmd "doas chown -R _nsd:_nsd /var/nsd/zones/master"

log "Creating zone files with DNSSEC signing"
for domain in "${(@k)all_domains}"; do
  serial=$(date +"%Y%m%d%H")

  log "Creating zone file for domain: $domain"
  doas tee "/var/nsd/zones/master/$domain.zone" > /dev/null << EOF
\$ORIGIN $domain.
\$TTL 24h

@ IN SOA ns.brgen.no. admin.brgen.no. ($serial 1h 15m 1w 3m)
@ IN NS ns.brgen.no.
@ IN NS ns.hyp.net.

www IN CNAME @

@ IN A $main_ip
EOF

  if [[ -n "${all_domains[$domain]}" ]]; then
    for subdomain in ${(s/ /)all_domains[$domain]}; do
      echo "$subdomain IN CNAME @" | doas tee -a "/var/nsd/zones/master/$domain.zone" > /dev/null
    done
  fi

  # DNSSEC key generation and zone signing
  log "Generating DNSSEC keys for $domain using ldns-keygen"
  cd /var/nsd/zones/master
  
  # Generate Zone Signing Key (ZSK)
  zsk_keyname=$(ldns-keygen -a ECDSAP256SHA256 -b 256 $domain)
  
  # Generate Key Signing Key (KSK)  
  ksk_keyname=$(ldns-keygen -k -a ECDSAP256SHA256 -b 256 $domain)
  
  # Set proper permissions for keys
  run_cmd "doas chown _nsd:_nsd $zsk_keyname.* $ksk_keyname.*"
  
  # Sign the zone with both keys
  log "Signing zone $domain with DNSSEC keys"
  ldns-signzone -n -p -s "$(openssl rand -hex 8)" "$domain.zone" "$zsk_keyname" "$ksk_keyname"
  
  # Generate DS record for parent zone delegation
  ldns-key2ds -n -2 "$ksk_keyname.key" > "$domain.ds"
  
  log "DNSSEC setup complete for $domain - DS record saved to $domain.ds"
  cd - >/dev/null
done

log "Creating NSD configuration file with DNSSEC support"
doas tee /etc/nsd/nsd.conf > /dev/null << EOF
server:
  ip-address: $main_ip
  hide-version: yes
  zonesdir: "/var/nsd/zones"

remote-control:
  control-enable: yes

pattern:
  name: "default"
  zonefile: "%s.zone.signed"
  notify: yes
  provide-xfr: $hyp_ip NOKEY

zone:
  name: "brgen.no"
  include-pattern: "default"

EOF

for domain in "${(@k)all_domains}"; do
  log "Adding zone configuration for domain: $domain"
  doas tee -a /etc/nsd/nsd.conf > /dev/null << EOF
zone:
  name: "$domain"
  include-pattern: "default"
EOF
done

log "Enabling and starting NSD with DNSSEC"
run_cmd "doas rcctl enable nsd"
run_cmd "doas rcctl start nsd"

# -- Enhanced App User Accounts and Service Management --

log "Setting up app user accounts and directories with enhanced security"
for app in "${(@k)apps_domains}"; do
  log "Creating user and directories for app: $app"
  run_cmd "doas useradd -m -G www -s /sbin/nologin $app" || log "User $app may already exist"
  run_cmd "doas mkdir -p /home/$app/{public,config,log,tmp}"
  run_cmd "doas chown -R $app:www /home/$app"
  run_cmd "doas chmod 755 /home/$app"
  run_cmd "doas chmod 700 /home/$app/{config,log}"
done

# Call PostgreSQL setup function
setup_postgresql

# -- Enhanced Service Configuration with Fixed Ports --

log "Setting up system services for apps with fixed port mapping"
for app in "${(@k)apps_domains}"; do
  port=${app_ports[$app]}
  log "Configuring service for app: $app on fixed port: $port"

  doas tee /etc/rc.d/$app > /dev/null << 'EOF'
#!/bin/ksh
daemon="/home/$app/bin/$app"
daemon_user="$app"
daemon_flags="-p $port"

. /etc/rc.d/rc.subr

rc_bg=YES
rc_reload=NO

rc_cmd $1
EOF
  run_cmd "doas chmod +x /etc/rc.d/$app"
  run_cmd "doas rcctl enable $app"
  # Note: Services will be started after apps are deployed
done

# -- Cleanup with zap --

cleanup_with_zap() {
    log "Cleaning up system with zap utility"
    if command -v zap >/dev/null 2>&1; then
        run_cmd "zap -f"
        log "System cleanup completed with zap"
    else
        log "Warning: zap not available, skipping cleanup"
    fi
}

# -- Redis Setup --

setup_redis() {
    log "Setting up Redis for application caching"
    run_cmd "doas rcctl enable redis"
    run_cmd "doas rcctl start redis"
    log "Redis setup completed"
}

# Execute setup functions
setup_redis
cleanup_with_zap

log "Setup complete. Your OpenBSD server is now configured for multiple Rails apps with:"
log "- Enhanced security (SSH brute-force protection, DoS protection)"
log "- Complete PostgreSQL setup with per-app databases"
log "- DNSSEC implementation with ldns-utils and zone signing"
log "- Fixed port mapping for applications"
log "- Comprehensive logging and error handling"
log "- Security headers in relayd configuration"

echo ""
echo "=== SETUP COMPLETED SUCCESSFULLY ==="
echo "Key features implemented:"
echo "• PostgreSQL: Complete database setup for each application"
echo "• DNSSEC: Full implementation with ldns-utils and ECDSAP256SHA256 keys"
echo "• Security: Enhanced PF firewall with brute-force and DoS protection"
echo "• Port Mapping: Fixed structured ports (brgen:3000, bsdports:3001, neuroticerotic:3002)"
echo "• Logging: JSON-formatted structured logging with timestamps"
echo "• Cleanup: zap utility integration for system maintenance"
echo ""
echo "DS records for DNSSEC delegation are available in /var/nsd/zones/master/*.ds"
echo "Submit these to your domain registrar for DNSSEC activation"
echo ""
echo "Services status:"
run_cmd "doas rcctl check postgresql redis nsd httpd relayd pf"

# -- INSTALLATION COMPLETE --