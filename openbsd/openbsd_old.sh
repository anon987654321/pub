#!/bin/bash

#!/usr/bin/env zsh

echo "OPENBSD SERVER SETUP FOR MULTIPLE RAILS APPS"

main_ip="46.23.95.45"

# Define all domains, subdomains and associated apps
typeset -A all_domains
all_domains=(
  ["brgen.no"]="markedsplass playlist dating tv takeaway maps"
  ["oshlo.no"]="markedsplass playlist dating tv takeaway maps"
  ["trndheim.no"]="markedsplass playlist dating tv takeaway maps"
  ["stvanger.no"]="markedsplass playlist dating tv takeaway maps"
  ["trmso.no"]="markedsplass playlist dating tv takeaway maps"
  ["longyearbyn.no"]="markedsplass playlist dating tv takeaway maps"
  ["reykjavk.is"]="markadur playlist dating tv takeaway maps"
  ["kobenhvn.dk"]="markedsplads playlist dating tv takeaway maps"
  ["stholm.se"]="marknadsplats playlist dating tv takeaway maps"
  ["gteborg.se"]="marknadsplats playlist dating tv takeaway maps"
  ["mlmoe.se"]="marknadsplats playlist dating tv takeaway maps"
  ["hlsinki.fi"]="markkinapaikka playlist dating tv takeaway maps"
  ["lndon.uk"]="marketplace playlist dating tv takeaway maps"
  ["mnchester.uk"]="marketplace playlist dating tv takeaway maps"
  ["brmingham.uk"]="marketplace playlist dating tv takeaway maps"
  ["edinbrgh.uk"]="marketplace playlist dating tv takeaway maps"
  ["glasgw.uk"]="marketplace playlist dating tv takeaway maps"
  ["lverpool.uk"]="marketplace playlist dating tv takeaway maps"
  ["amstrdam.nl"]="marktplaats playlist dating tv takeaway maps"
  ["rottrdam.nl"]="marktplaats playlist dating tv takeaway maps"
  ["utrcht.nl"]="marktplaats playlist dating tv takeaway maps"
  ["brssels.be"]="marche playlist dating tv takeaway maps"
  ["zrich.ch"]="marktplatz playlist dating tv takeaway maps"
  ["lchtenstein.li"]="marktplatz playlist dating tv takeaway maps"
  ["frankfrt.de"]="marktplatz playlist dating tv takeaway maps"
  ["mrseille.fr"]="marche playlist dating tv takeaway maps"
  ["mlan.it"]="mercato playlist dating tv takeaway maps"
  ["lsbon.pt"]="mercado playlist dating tv takeaway maps"
  ["lsangeles.com"]="marketplace playlist dating tv takeaway maps"
  ["newyrk.us"]="marketplace playlist dating tv takeaway maps"
  ["chcago.us"]="marketplace playlist dating tv takeaway maps"
  ["dtroit.us"]="marketplace playlist dating tv takeaway maps"
  ["houstn.us"]="marketplace playlist dating tv takeaway maps"
  ["dllas.us"]="marketplace playlist dating tv takeaway maps"
  ["austn.us"]="marketplace playlist dating tv takeaway maps"
  ["prtland.com"]="marketplace playlist dating tv takeaway maps"
  ["mnneapolis.com"]="marketplace playlist dating tv takeaway maps"
  ["pub.healthcare"]=""
  ["pub.attorney"]=""
  ["freehelp.legal"]=""
  ["bsdports.org"]=""
  ["discordb.org"]=""
  ["foodielicio.us"]=""
  ["neuroticerotic.com"]=""
)

# Define apps and their associated domains
typeset -A apps_domains
apps_domains=(
  ["brgen"]="brgen.no"
  ["bsdports"]="bsdports.org"
  ["neuroticerotic"]="neuroticerotic.com"
)

# Logging and error handling functions
LOG_FILE="./openbsd_setup.log"

log() {
    local message="$1"
    printf '{"timestamp":"%s","level":"INFO","message":"%s"}\n' \
        "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$message" >> "$LOG_FILE"
}

run() {
    if ! eval "$@"; then
        log "Error: Command failed: $*"
        exit 1
    fi
}

# -- INSTALLATION BEGIN --

echo "Installing necessary packages..."
log "Installing system packages"
run pkg_add -U ruby postgresql-client dnscrypt-proxy ldns-utils zap

# -- PF --

echo "Setting up pf.conf..."
log "Configuring pf firewall"
doas tee /etc/pf.conf > /dev/null << "EOF"
ext_if = "vio0"

# Skip filtering on loopback interfaces
set skip on lo

# Table to track brute force attempts
table <bruteforce> persist

# Return RSTs instead of silently dropping
set block-policy return

# Enable logging on external interface
set loginterface $ext_if

# Don't filter on loopback interface
set skip on lo0

# Normalize all incoming traffic
scrub in all

# Block all traffic by default
block log all

# Allow all outgoing traffic
pass out quick on $ext_if all

# Prevent SSH brute-force attacks with connection limits
pass in on $ext_if proto tcp to port 22 keep state (max-src-conn 2, max-src-conn-rate 2/60, overload <bruteforce>)

# Allow HTTP/HTTPS with connection limits to prevent DoS
pass in on $ext_if proto tcp to port { 80, 443 } keep state (max-src-conn 100, max-src-conn-rate 100/60)

# Allow DNS queries with state tracking
pass in on $ext_if proto { tcp, udp } to port 53 keep state

# Allow ICMP traffic (ping, etc.)
pass inet proto icmp all icmp-type { echoreq, unreach, timex, paramprob }
EOF

# -- RELAYD --

echo "Configuring relayd.conf..."
doas tee /etc/relayd.conf > /dev/null << EOF
egress "$main_ip"
EOF

for app in "${(@k)apps_domains}"; do
  domain=${apps_domains[$app]}
  port=$((RANDOM % 10000 + 40000))

  echo "Adding relayd configuration for app: $app, domain: $domain, port: $port"
  doas tee -a /etc/relayd.conf > /dev/null << EOF

table <${app}> { 127.0.0.1 }

protocol "http_protocol_${app}" {
  # Forward client IP for logging
  match request header set "X-Forwarded-By" value "\$SERVER_ADDR:\$SERVER_PORT"
  match request header set "X-Forwarded-For" value "\$REMOTE_ADDR"
  # Indicate HTTPS protocol
  match request header set "X-Forwarded-Proto" value "https"
  
  # Enhanced security headers
  match response header set "Content-Security-Policy" value "upgrade-insecure-requests; default-src https:; style-src 'self' 'unsafe-inline'; font-src 'self' data:; script-src 'self' 'unsafe-inline' 'unsafe-eval'"
  # Enforce HTTPS for one year, including subdomains (prevents downgrade attacks)
  match response header set "Strict-Transport-Security" value "max-age=31536000; includeSubDomains; preload"
  match response header set "Referrer-Policy" value "strict-origin"
  match response header set "Feature-Policy" value "accelerometer 'none'; camera 'none'; microphone 'none'"
  # Prevent MIME-type sniffing (mitigates drive-by downloads)
  match response header set "X-Content-Type-Options" value "nosniff"
  match response header set "X-Download-Options" value "noopen"
  # Block framing to prevent clickjacking
  match response header set "X-Frame-Options" value "DENY"
  # Enable XSS filtering in browsers (mitigates reflected XSS)
  match response header set "X-XSS-Protection" value "1; mode=block"

  tcp { no delay }

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

echo "Enabling and starting relayd..."
doas rcctl enable relayd
doas rcctl start relayd

# -- HTTPD --

echo "Configuring httpd.conf..."
doas tee /etc/httpd.conf > /dev/null << EOF
server "default" {
  listen on * port 80
  location "/.well-known/acme-challenge/*" {
    root "/acme"
    request strip 2
  }
}
EOF

echo "Creating directory for ACME challenges..."
doas mkdir -p /var/www/acme
run chown -R www:www /var/www/acme

echo "Setting up acme-client.conf..."
# Generate ACME account key if it doesn't exist
if [ ! -f /etc/acme/letsencrypt.pem ]; then
    run openssl ecparam -name prime256v1 -genkey -out /etc/acme/letsencrypt.pem
fi

doas tee /etc/acme-client.conf > /dev/null << EOF
authority letsencrypt {
  api url "https://acme-v02.api.letsencrypt.org/directory"
  account key "/etc/acme/letsencrypt.pem"
}

authority letsencrypt-staging {
  api url "https://acme-staging-v02.api.letsencrypt.org/directory"
  account key "/etc/acme/letsencrypt-staging-privkey.pem"
}
EOF

for domain in "${(@k)all_domains}"; do
  echo "Adding ACME configuration for domain: $domain"
  doas tee -a /etc/acme-client.conf > /dev/null << EOF
domain "$domain" {
  alternative name { $(echo ${all_domains[$domain]} | sed 's/ /", "/g') }
  domain key "/etc/ssl/private/$domain.key"
  domain fullchain "/etc/ssl/acme/$domain.fullchain"
  domain chain "/etc/ssl/acme/$domain.chain"
  domain cert "/etc/ssl/acme/$domain.crt"

  sign with letsencrypt
}
EOF

  # Generate SSL certificates with retry logic
  echo "Generating SSL certificate for $domain"
  if ! run timeout 120 acme-client -v "$domain"; then
      log "Warning: acme-client failed for $domain, retrying after delay"
      sleep 5
      run timeout 120 acme-client -v "$domain"
  fi
done

echo "Enabling and starting httpd..."
doas rcctl enable httpd
doas rcctl start httpd

# -- NSD --

echo "Setting up NSD with DNSSEC..."
log "Setting up NSD and DNSSEC"

echo "Creating zones with DNSSEC support..."
doas mkdir -p /var/nsd/zones/master /etc/nsd
run chown _nsd:_nsd /var/nsd/zones/master

for domain in "${(@k)all_domains}"; do
  serial=$(date +"%Y%m%d%H")

  echo "Creating zone file for domain: $domain"
  log "Processing domain: $domain"
  doas tee "/var/nsd/zones/master/$domain.zone" > /dev/null << EOF
\$ORIGIN $domain.
\$TTL 24h

@ IN SOA ns.brgen.no. admin.brgen.no. ($serial 1h 15m 1w 3m)
@ IN NS ns.brgen.no.
@ IN NS ns.hyp.net.

www IN CNAME @

@ IN A $main_ip
@ IN CAA 0 issue "letsencrypt.org"
EOF

  if [[ -n "${all_domains[$domain]}" ]]; then
    for subdomain in ${(s/ /)all_domains[$domain]}; do
      echo "$subdomain IN CNAME @" | doas tee -a "/var/nsd/zones/master/$domain.zone" > /dev/null
    done
  fi

  # DNSSEC key generation and zone signing
  echo "Generating DNSSEC keys for $domain"
  cd /var/nsd/zones/master
  zsk=$(run ldns-keygen -a ECDSAP256SHA256 -b 256 "$domain")
  ksk=$(run ldns-keygen -k -a ECDSAP256SHA256 -b 256 "$domain")
  run chown _nsd:_nsd "$zsk".* "$ksk".*
  run ldns-signzone -n -p -s "$(openssl rand -hex 8)" "$domain.zone" "$zsk" "$ksk"
  cd - >/dev/null
  
  log "DNSSEC keys generated and zone signed for $domain"
done

echo "Creating NSD configuration file..."
doas tee /var/nsd/etc/nsd.conf > /dev/null << EOF
server:
  ip-address: $main_ip
  hide-version: yes
  zonesdir: "/var/nsd/zones"

remote-control:
  control-enable: yes
EOF

for domain in "${(@k)all_domains}"; do
  echo "Adding zone configuration for domain: $domain"
  doas tee -a /var/nsd/etc/nsd.conf > /dev/null << EOF

zone:
  name: "$domain"
  zonefile: "master/$domain.zone.signed"
  provide-xfr: 194.63.248.53 NOKEY
  notify: 194.63.248.53 NOKEY
EOF
done

echo "Enabling and starting NSD..."
doas rcctl enable nsd
doas rcctl start nsd

# Reload NSD configuration to apply DNSSEC changes
echo "Reloading NSD configuration..."
run nsd-control reload
log "NSD setup with DNSSEC complete"

# -- APP USER ACCOUNTS --

echo "Setting up app user accounts and directories..."
for app in "${(@k)apps_domains}"; do
  echo "Creating user and directories for app: $app"
  doas useradd -m -G www -s /sbin/nologin $app
  doas mkdir -p /home/$app/{public,config,log}
  doas chown -R $app:www /home/$app
done

# -- Service Configuration --

echo "Setting up system services for apps..."
for app in "${(@k)apps_domains}"; do
  port=$((RANDOM % 10000 + 40000))
  echo "Configuring service for app: $app on port: $port"

  doas tee /etc/rc.d/$app > /dev/null << EOF
#!/bin/ksh
daemon="/home/$app/bin/$app"
daemon_user="$app"
daemon_flags="-p $port"

. /etc/rc.d/rc.subr

rc_bg=YES
rc_reload=NO

rc_cmd \$1
EOF
  doas chmod +x /etc/rc.d/$app
  doas rcctl enable $app
  doas rcctl start $app
done

# -- CLEANUP FUNCTION --

cleanup_nsd() {
    echo "Performing NSD cleanup with zap..."
    log "Cleaning up NSD with zap"
    
    if ! run zap -f nsd; then
        log "Warning: zap cleanup failed, continuing anyway"
    fi
    
    run nsd-control reload
    log "NSD cleanup complete"
}

# Optional cleanup - uncomment the next line to enable
# cleanup_nsd

echo "Setup complete. Your OpenBSD server is now configured for multiple Rails apps with DNSSEC support."
log "OpenBSD setup with DNSSEC complete"

# -- INSTALLATION COMPLETE --
