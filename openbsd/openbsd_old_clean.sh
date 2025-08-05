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

# -- INSTALLATION BEGIN --

echo "Installing necessary packages..."
doas pkg_add -U ruby postgresql-client dnscrypt-proxy

# -- PF --

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

# Allow incoming SSH, HTTP, and HTTPS traffic
pass in on $ext_if proto tcp to $ext_if port { 22, 80, 443 } keep state

# Allow incoming DNS traffic
pass in on $ext_if proto { tcp, udp } to $ext_if port 53 keep state

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
  match request header set "X-Forwarded-By" value "\$SERVER_ADDR:\$SERVER_PORT"
  match request header set "X-Forwarded-For" value "\$REMOTE_ADDR"
  match response header set "Content-Security-Policy" value "upgrade-insecure-requests; default-src https:; style-src 'self' 'unsafe-inline'; font-src 'self' data:; script-src 'self' 'unsafe-inline' 'unsafe-eval'"
  match response header set "Strict-Transport-Security" value "max-age=31536000; includeSubDomains; preload"
  match response header set "Referrer-Policy" value "strict-origin"
  match response header set "Feature-Policy" value "accelerometer 'none'; ..."
  match response header set "X-Content-Type-Options" value "nosniff"
  match response header set "X-Download-Options" value "noopen"
  match response header set "X-Frame-Options" value "DENY"
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

echo "Setting up acme-client.conf..."
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
done

echo "Enabling and starting httpd..."
doas rcctl enable httpd
doas rcctl start httpd

# -- NSD --

echo "Setting up NSD..."

echo "Creating zones..."
doas mkdir -p /var/nsd/zones/master /etc/nsd

for domain in "${(@k)all_domains}"; do
  serial=$(date +"%Y%m%d%H")

  echo "Creating zone file for domain: $domain"
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
done

echo "Creating NSD configuration file..."
doas tee /etc/nsd/nsd.conf > /dev/null << EOF
server:
  ip-address: 0.0.0.0
  hide-version: yes
  zonesdir: "/var/nsd/zones"

remote-control:
  control-enable: yes

pattern:
  name: "default"
  zonefile: "%s.zone"
  notify: yes
  provide-xfr: 203.0.113.2 NOKEY

zone:
  name: "brgen.no"
  include-pattern: "default"

EOF

for domain in "${(@k)all_domains}"; do
  echo "Adding zone configuration for domain: $domain"
  doas tee -a /etc/nsd/nsd.conf > /dev/null << EOF
zone:
  name: "$domain"
  include-pattern: "default"
EOF
done

echo "Enabling and starting NSD..."
doas rcctl enable nsd
doas rcctl start nsd

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

echo "Setup complete. Your OpenBSD server is now configured for multiple Rails apps."

# -- INSTALLATION COMPLETE --
