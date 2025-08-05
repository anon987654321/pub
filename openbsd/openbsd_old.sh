#!/usr/bin/env zsh

# Configures OpenBSD for multiple Rails applications with enhanced security,
# proper error handling, and structured service management.
# Usage: doas zsh openbsd_old.sh
# Updated: $(date -u +%Y-%m-%dT%H:%M:%SZ)

set -e
set -x

echo "OPENBSD SERVER SETUP FOR MULTIPLE RAILS APPS"

LOG_FILE="./openbsd_setup.log"
main_ip="46.23.95.45"

# Structured logging function
log() {
    local message="$1"
    printf '{"timestamp":"%s","level":"INFO","message":"%s"}\n' \
        "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$message" | tee -a "$LOG_FILE"
}

# Define all domains, subdomains and associated apps
typeset -A all_domains

# Use a different syntax to avoid floating point interpretation
all_domains[brgen.no]='markedsplass playlist dating tv takeaway maps'
all_domains[oshlo.no]='markedsplass playlist dating tv takeaway maps'
all_domains[trndheim.no]='markedsplass playlist dating tv takeaway maps'
all_domains[stvanger.no]='markedsplass playlist dating tv takeaway maps'
all_domains[trmso.no]='markedsplass playlist dating tv takeaway maps'
all_domains[longyearbyn.no]='markedsplass playlist dating tv takeaway maps'
all_domains[reykjavk.is]='markadur playlist dating tv takeaway maps'
all_domains[kobenhvn.dk]='markedsplads playlist dating tv takeaway maps'
all_domains[stholm.se]='marknadsplats playlist dating tv takeaway maps'
all_domains[gteborg.se]='marknadsplats playlist dating tv takeaway maps'
all_domains[mlmoe.se]='marknadsplats playlist dating tv takeaway maps'
all_domains[hlsinki.fi]='markkinapaikka playlist dating tv takeaway maps'
all_domains[lndon.uk]='marketplace playlist dating tv takeaway maps'
all_domains[mnchester.uk]='marketplace playlist dating tv takeaway maps'
all_domains[brmingham.uk]='marketplace playlist dating tv takeaway maps'
all_domains[edinbrgh.uk]='marketplace playlist dating tv takeaway maps'
all_domains[glasgw.uk]='marketplace playlist dating tv takeaway maps'
all_domains[lverpool.uk]='marketplace playlist dating tv takeaway maps'
all_domains[amstrdam.nl]='marktplaats playlist dating tv takeaway maps'
all_domains[rottrdam.nl]='marktplaats playlist dating tv takeaway maps'
all_domains[utrcht.nl]='marktplaats playlist dating tv takeaway maps'
all_domains[brssels.be]='marche playlist dating tv takeaway maps'
all_domains[zrich.ch]='marktplatz playlist dating tv takeaway maps'
all_domains[lchtenstein.li]='marktplatz playlist dating tv takeaway maps'
all_domains[frankfrt.de]='marktplatz playlist dating tv takeaway maps'
all_domains[mrseille.fr]='marche playlist dating tv takeaway maps'
all_domains[mlan.it]='mercato playlist dating tv takeaway maps'
all_domains[lsbon.pt]='mercado playlist dating tv takeaway maps'
all_domains[lsangeles.com]='marketplace playlist dating tv takeaway maps'
all_domains[newyrk.us]='marketplace playlist dating tv takeaway maps'
all_domains[chcago.us]='marketplace playlist dating tv takeaway maps'
all_domains[dtroit.us]='marketplace playlist dating tv takeaway maps'
all_domains[houstn.us]='marketplace playlist dating tv takeaway maps'
all_domains[dllas.us]='marketplace playlist dating tv takeaway maps'
all_domains[austn.us]='marketplace playlist dating tv takeaway maps'
all_domains[prtland.com]='marketplace playlist dating tv takeaway maps'
all_domains[mnneapolis.com]='marketplace playlist dating tv takeaway maps'
all_domains[pub.healthcare]=''
all_domains[pub.attorney]=''
all_domains[freehelp.legal]=''
all_domains[bsdports.org]=''
all_domains[discordb.org]=''
all_domains[foodielicio.us]=''
all_domains[neuroticerotic.com]=''

# Define apps and their associated domains
# Define apps and their associated domains
typeset -A apps_domains
typeset -A app_ports

# Use simpler syntax to avoid issues
apps_domains[brgen]='brgen.no'
apps_domains[bsdports]='bsdports.org'
apps_domains[neuroticerotic]='neuroticerotic.com'

# Define structured port mapping instead of random assignment
app_ports[brgen]=3000
app_ports[bsdports]=3001
app_ports[neuroticerotic]=3002

# -- INSTALLATION BEGIN --

log "Starting OpenBSD setup for multiple Rails applications"

echo "Installing necessary packages..."
log "Installing system packages"
doas pkg_add -U ruby postgresql-server redis falcon postgresql-client dnscrypt-proxy

# -- PF --

log "Configuring pf firewall"
echo "Setting up pf.conf..."
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
pass in on $ext_if proto tcp to $ext_if port 22 keep state (max-src-conn 2, max-src-conn-rate 2/60, overload <bruteforce>)

# Allow incoming HTTP, and HTTPS traffic with connection limits
pass in on $ext_if proto tcp to $ext_if port { 80, 443 } keep state (max-src-conn 100, max-src-conn-rate 100/60)

# Allow incoming DNS traffic
pass in on $ext_if proto { tcp, udp } to $ext_if port 53 keep state

# Allow ICMP traffic (ping, etc.)
pass inet proto icmp all icmp-type { echoreq, unreach, timex, paramprob }

# Anchor for relayd rules
anchor "relayd/*"
EOF

log "pf firewall configuration completed"

# -- RELAYD --

log "Configuring relayd with enhanced security headers"
echo "Configuring relayd.conf..."

# Create the base relayd configuration
doas tee /etc/relayd.conf > /dev/null << EOF
# Main IP address
egress "$main_ip"

# Table for ACME HTTP challenges
table <httpd> { 127.0.0.1:80 }

# HTTP protocol for ACME challenges and redirection
http protocol "http_acme" {
    # Forward client IP for logging
    match request header set "X-Forwarded-For" value "\$REMOTE_ADDR"
    # Pass ACME challenge requests
    pass request path "/.well-known/acme-challenge/*" forward to <httpd>
    # Redirect HTTP to HTTPS (prevents downgrade attacks)
    match request header "Host" tag "redirect"
    match request tagged "redirect" header set "Location" value "https://\$HTTP_HOST\$REQUEST_URI"
    match request tagged "redirect" return code 301
}

# HTTPS protocol with enhanced security headers
http protocol "https_production" {
    # Forward client IP and protocol
    match request header set "X-Forwarded-For" value "\$REMOTE_ADDR"
    match request header set "X-Forwarded-Proto" value "https"
    
    # Security headers
    match response header set "Strict-Transport-Security" value "max-age=31536000; includeSubDomains; preload"
    match response header set "Content-Security-Policy" value "upgrade-insecure-requests; default-src https:; style-src 'self' 'unsafe-inline'; font-src 'self' data:; script-src 'self' 'unsafe-inline' 'unsafe-eval'"
    match response header set "X-Content-Type-Options" value "nosniff"
    match response header set "X-Frame-Options" value "DENY"
    match response header set "X-XSS-Protection" value "1; mode=block"
    match response header set "Referrer-Policy" value "strict-origin"
    
    # Performance optimizations
    tcp { no delay }
    request timeout 20
    session timeout 60
    
    # WebSocket support
    http websockets
}

# Relay for HTTP-to-HTTPS redirection
relay "http_redirect" {
    listen on \$egress port 80
    protocol "http_acme"
    forward to <httpd> port 80
}
EOF

# Add backend tables and HTTPS relay configuration for each app
for app in "${(@k)apps_domains}"; do
  domain=${apps_domains[$app]}
  port=${app_ports[$app]}

  log "Adding relayd configuration for app: $app, domain: $domain, port: $port"
  
  doas tee -a /etc/relayd.conf > /dev/null << EOF

# Backend table for $app
table <${app}_backend> { 127.0.0.1:$port }
EOF
done

# Create the HTTPS relay that handles all domains
doas tee -a /etc/relayd.conf > /dev/null << EOF

# Main HTTPS relay with domain routing
relay "https_main" {
    listen on \$egress port 443 tls
    protocol "https_production"
EOF

# Add domain-specific routing
for app in "${(@k)apps_domains}"; do
  domain=${apps_domains[$app]}
  doas tee -a /etc/relayd.conf > /dev/null << EOF
    match request header "Host" value "$domain" forward to <${app}_backend>
EOF
done

doas tee -a /etc/relayd.conf > /dev/null << EOF
}
EOF

log "relayd configuration completed"
echo "Enabling and starting relayd..."
doas rcctl enable relayd
doas rcctl start relayd

# -- HTTPD --

log "Configuring httpd for ACME challenges"
echo "Configuring httpd.conf..."
doas tee /etc/httpd.conf > /dev/null << EOF
types { include "/usr/share/misc/mime.types" }

# Serve ACME challenges for Let's Encrypt
server "acme" {
    listen on * port 80
    root "/var/www/acme"
    location "/.well-known/acme-challenge/*" {
        root "/acme"
        request strip 2
    }
}
EOF

echo "Creating directory for ACME challenges..."
doas mkdir -p /var/www/acme
doas chown -R www:www /var/www/acme

echo "Setting up acme-client.conf..."
doas mkdir -p /etc/acme
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

log "httpd configuration completed"

# Process domains for SSL certificates
log "Processing domains for SSL certificate configuration"
for domain in "${(@k)all_domains}"; do
  echo "Adding ACME configuration for domain: $domain"
  log "Configuring SSL certificate for domain: $domain"
  
  # Handle domains with subdomains
  if [[ -n "${all_domains[$domain]}" ]]; then
    # Convert space-separated list to quoted, comma-separated alternative names
    alternative_names=$(echo "${all_domains[$domain]}" | sed 's/[^ ]*/&.'"$domain"'/g' | sed 's/ /", "/g')
    doas tee -a /etc/acme-client.conf > /dev/null << EOF
domain "$domain" {
  alternative names { "$alternative_names" }
  domain key "/etc/ssl/private/$domain.key"
  domain certificate "/etc/ssl/$domain.crt" 
  domain full chain certificate "/etc/ssl/$domain.fullchain.pem"
  sign with letsencrypt
  challengedir "/var/www/acme"
}
EOF
  else
    # Domain without subdomains
    doas tee -a /etc/acme-client.conf > /dev/null << EOF
domain "$domain" {
  domain key "/etc/ssl/private/$domain.key"
  domain certificate "/etc/ssl/$domain.crt"
  domain full chain certificate "/etc/ssl/$domain.fullchain.pem"
  sign with letsencrypt
  challengedir "/var/www/acme"
}
EOF
  fi
done

log "SSL certificate configuration completed"

echo "Enabling and starting httpd..."
doas rcctl enable httpd
doas rcctl start httpd
log "httpd service started"

# -- NSD --

log "Setting up NSD with enhanced configuration"
echo "Setting up NSD..."

echo "Creating zones..."
doas mkdir -p /var/nsd/zones/master /etc/nsd
doas chown -R _nsd:_nsd /var/nsd/zones/master

# Create zone files for all domains
log "Creating DNS zone files"
for domain in "${(@k)all_domains}"; do
  serial=$(date +"%Y%m%d%H")

  echo "Creating zone file for domain: $domain"
  log "Processing DNS zone for domain: $domain"
  
  doas tee "/var/nsd/zones/master/$domain.zone" > /dev/null << EOF
\$ORIGIN $domain.
\$TTL 3600

@ IN SOA ns.brgen.no. hostmaster.$domain. (
    $serial 3600 1800 1209600 1800
)
@ IN NS ns.brgen.no.
@ IN NS ns.hyp.net.

www IN CNAME @
@ IN A $main_ip

; Mail configuration
mail IN A $main_ip
@ IN MX 10 mail.$domain.

; CAA records for Let's Encrypt
@ IN CAA 0 issue "letsencrypt.org"
EOF

  # Add subdomain records if they exist
  if [[ -n "${all_domains[$domain]}" ]]; then
    for subdomain in ${=all_domains[$domain]}; do
      echo "$subdomain IN A $main_ip" | doas tee -a "/var/nsd/zones/master/$domain.zone" > /dev/null
    done
  fi
  
  # Set proper ownership
  doas chown _nsd:_nsd "/var/nsd/zones/master/$domain.zone"
done

log "DNS zone files created"

echo "Creating NSD configuration file..."
log "Creating NSD configuration"
doas tee /etc/nsd/nsd.conf > /dev/null << EOF
server:
  ip-address: $main_ip
  hide-version: yes
  zonesdir: "/var/nsd/zones"
  
  # Security and performance settings
  server-count: 2
  tcp-count: 100
  tcp-query-count: 0
  tcp-timeout: 120

remote-control:
  control-enable: yes

pattern:
  name: "default"
  zonefile: "master/%s.zone"
  notify: 194.63.248.53 NOKEY
  provide-xfr: 194.63.248.53 NOKEY

EOF

# Add zone configurations for all domains
log "Adding zone configurations to NSD"
for domain in "${(@k)all_domains}"; do
  echo "Adding zone configuration for domain: $domain"
  doas tee -a /etc/nsd/nsd.conf > /dev/null << EOF
zone:
  name: "$domain"
  include-pattern: "default"

EOF
done

log "NSD configuration completed"

echo "Enabling and starting NSD..."
doas rcctl enable nsd
doas rcctl start nsd
log "NSD service started"

# -- POSTGRESQL SETUP --

log "Setting up PostgreSQL database service"
echo "Configuring PostgreSQL..."

# Initialize PostgreSQL if not already done
if [ ! -d /var/postgresql/data ]; then
    echo "Initializing PostgreSQL database..."
    doas install -d -o _postgresql -g _postgresql /var/postgresql/data
    doas -u _postgresql initdb -D /var/postgresql/data -U postgres -A scram-sha-256 -E UTF8
    log "PostgreSQL database initialized"
fi

# Enable and start PostgreSQL
doas rcctl enable postgresql
doas rcctl start postgresql
log "PostgreSQL service started"

# -- APP USER ACCOUNTS --

log "Setting up application user accounts and databases"
echo "Setting up app user accounts and directories..."
for app in "${(@k)apps_domains}"; do
  echo "Creating user and directories for app: $app"
  log "Setting up user account for app: $app"
  
  # Create user if it doesn't exist
  if ! id "$app" >/dev/null 2>&1; then
    doas useradd -m -G www -s /sbin/nologin "$app"
  fi
  
  # Create application directories
  doas mkdir -p "/home/$app"/{app,public,config,log}
  doas chown -R "$app":www "/home/$app"
  
  # Create database user and database
  port=${app_ports[$app]}
  db_password=$(openssl rand -hex 16)
  
  echo "Creating database for app: $app"
  log "Creating PostgreSQL database for app: $app"
  
  # Create database user
  doas -u _postgresql psql -U postgres -c "CREATE ROLE ${app}_user LOGIN PASSWORD '$db_password';" 2>/dev/null || true
  
  # Create database
  doas -u _postgresql createdb -O "${app}_user" "${app}_db" 2>/dev/null || true
  
  # Store database credentials securely
  doas tee "/home/$app/.env.production" > /dev/null << EOF
RAILS_ENV=production
SECRET_KEY_BASE=$(openssl rand -hex 64)
DATABASE_URL=postgresql://${app}_user:$db_password@localhost/${app}_db
REDIS_URL=redis://localhost:6379/0
PORT=$port
EOF
  
  doas chown "$app":www "/home/$app/.env.production"
  doas chmod 600 "/home/$app/.env.production"
  
  log "Database and environment configured for app: $app"
done

# -- SERVICE CONFIGURATION --

log "Setting up application services with Falcon"
echo "Setting up system services for apps..."

# Enable Redis for application caching
doas rcctl enable redis
doas rcctl start redis
log "Redis service started"

for app in "${(@k)apps_domains}"; do
  port=${app_ports[$app]}
  echo "Configuring Falcon service for app: $app on port: $port"
  log "Creating Falcon service configuration for app: $app"

  doas tee "/etc/rc.d/$app" > /dev/null << EOF
#!/bin/ksh

# Service script for $app using Falcon web server
daemon_user="$app"
daemon_class="daemon"
daemon_execdir="/home/$app/app"
daemon_flags="--config /home/$app/app/config.ru --bind http://127.0.0.1:$port"
daemon="/usr/local/bin/falcon"

. /etc/rc.d/rc.subr

rc_bg=YES
rc_usercheck=YES

rc_start() {
    if [ ! -f "/home/$app/app/config.ru" ]; then
        echo "Error: /home/$app/app/config.ru not found"
        return 1
    fi
    cd "/home/$app/app"
    rc_exec "source /home/$app/.env.production && \$daemon \$daemon_flags"
}

rc_cmd \$1
EOF

  doas chmod +x "/etc/rc.d/$app"
  doas rcctl enable "$app"
  
  # Only start the service if the application exists
  if [ -f "/home/$app/app/config.ru" ]; then
    doas rcctl start "$app"
    log "Started Falcon service for app: $app"
  else
    log "Warning: Application files not found for $app, service created but not started"
  fi
done

log "Application services configuration completed"

# -- COMPLETION --

log "OpenBSD setup completed successfully"
echo "Setup complete. Your OpenBSD server is now configured for multiple Rails apps."
echo ""
echo "Next steps:"
echo "1. Upload your Rails applications to /home/<app>/app/ directories"
echo "2. Ensure each app has a config.ru file for Falcon"
echo "3. Obtain SSL certificates: doas acme-client <domain>"
echo "4. Check service status: doas rcctl check nsd httpd postgresql redis relayd"
echo ""
echo "Log file: $LOG_FILE"

# -- INSTALLATION COMPLETE --
