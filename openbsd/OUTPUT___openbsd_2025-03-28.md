# § Output Openbsd 2025-03-28

## `README.md`
```
# OpenBSD

Ruby On Rails, Falcon and gems run from an unprivileged user account that that only owns `tmp/` and `log/`.
<!-- TODO: Break into shorter sentences (29 words > 15) --> This ensures not only that the root system remains unaffected from a break-in attempt, but that a compromised app will not have access to modify any of its runtime files.
<!-- TODO: Break into shorter sentences (30 words > 15) --> - `relayd(8)` reverse proxy listens on HTTP/2 and forwards connctions to Falcon in addition to handling all TLS, which is disabled internally in Rails to save resources.
<!-- TODO: Break into shorter sentences (27 words > 15) --> - `httpd(8)` and `acme-client(1)` listens on HTTP/1.1 for ACME-challenges for Let's Encrypt TLS certificate generation. - `pf(4)` is the firewall that together with `pf-badhost` blocks out some 600.000.000 bad IP-addresses, and bans anyone who attempts SSH bruteforce attacks.
<!-- TODO: Break into shorter sentences (23 words > 15) --> On top of this `nsd(8)` handles DNS zonefiles and OpenSMTPD emails. - - -

*Edit configs to taste and deploy to root*

    # cp -R etc/ var/ /

*Create unprivileged user and group*

    # adduser -group USER -batch bsdports

## Ruby On Rails

    # pkg_add ruby
    # gem update --system

*Make Bundler always install things locally*

    $ bundle config set path $HOME/.bundle/

*Set the shell path*

    echo "PATH=$PATH:$HOME/.local/share/gem/ruby/3.1/bin; export PATH" >> ~/.kshrc
    .
<!-- TODO: Break into shorter sentences (62 words > 15) --> ~/.kshrc

*Nokogiri*

    # pkg_add libiconv libxml libxslt

    $ bundle config build.nokogiri --use-system-libraries
    $ gem install --user-install nokogiri -- --use-system-libraries

*Rails*

    $ gem install --user-install rails
    $ gem install --user-install falcon

To install 7.1-alpha:

    $ gem install --user-install specific_install
    $ gem git_install --user-install https://github.com/rails/rails.git -d activemodel
    $ gem git_install --user-install https://github.com/rails/rails.git -d activesupport
    $ gem git_install --user-install https://github.com/rails/rails.git -d activerecord
    $ gem git_install --user-install https://github.com/rails/rails.git -d activejob
    $ gem git_install --user-install https://github.com/rails/rails.git -d actionview
    $ gem git_install --user-install https://github.com/rails/rails.git -d actionpack
    $ gem git_install --user-install https://github.com/rails/rails.git -d actioncable
    $ gem git_install --user-install https://github.com/rails/rails.git -d actionmailbox
    $ gem git_install --user-install https://github.com/rails/rails.git -d actionmailer
    $ gem git_install --user-install https://github.com/rails/rails.git -d activestorage
    $ gem git_install --user-install https://github.com/rails/rails.git -d actiontext
    $ gem git_install --user-install https://github.com/rails/rails.git -d railties
    $ gem git_install --user-install https://github.com/rails/rails.git

## PostgreSQL

    # pkg_add postgresql-server

    # rcctl enable postgresql
    # doas -u _postgresql initdb -D /var/postgresql/data/ -U postgres
    # rcctl start postgresql
    # doas -u _postgresql psql -U postgres

    CREATE ROLE <user> LOGIN SUPERUSER PASSWORD '<password>';

## Redis

    # pkg_add redis

    # rcctl enable redis
    # rcctl start redis

## JavaScript

    # pkg_add node
    # npm install --global yarn

*Prevent Node errors*

    # ln -s /usr/local/bin/node /tmp/node

## CSS

    # pkg_add sass

## Images

    # pkg_add libvips glib2 gobject-introspection

    # ln -sf /usr/local/lib/libvips.so.0.0 /usr/local/lib/libvips.so.42
    # ln -sf /usr/local/lib/libglib-2.0.so.4201.8 /usr/local/lib/glib-2.0.so.0
    # ln -sf /usr/local/lib/libgobject-2.0.so.4200.15 /usr/local/lib/libgobject-2.0.so.0

## SSL certificates

    # rcctl enable httpd
    # rcctl start httpd

*Generates Let's Encrypt TLS-certificates with `acme-client(1)` and adds renewal to `crontab(1)`*

    # ./mkcert

## Firewall

Install [pf-badhost](https://www.geoghegan.ca/pub/pf-badhost/latest/install/openbsd.txt).
<!-- TODO: Break into shorter sentences (249 words > 15) --> ## DNS server

    # rcctl enable nsd
    # rcctl start nsd

## Email server

    # wget https://opensmtpd.org/archives/opensmtpd-6.7.1p1.tar.gz
    # tar xvzf opensmtpd-6.7.1p1.tar.gz
    # cd opensmtpd-6.7.1p1
    # ./configure && make && make install

    # rcctl enable smtpd
    # rcctl start smtpd

```

## `etc/acme-client.conf`
```
authority letsencrypt {
  api url "https://acme-v02.api.letsencrypt.org/directory"
  # api url "https://acme-staging-v02.api.letsencrypt.org/directory"
  account key "/etc/ssl/private/letsencrypt.key"
}

domain bsdports.net {
  alternative names { www.bsdports.net }
  domain key "/etc/ssl/private/bsdports.net.key"
  domain full chain certificate "/etc/ssl/bsdports.net.crt"
  sign with letsencrypt
}

domain bsdports.org {
  alternative names { www.bsdports.org }
  domain key "/etc/ssl/private/bsdports.org.key"
  domain full chain certificate "/etc/ssl/bsdports.org.crt"
  sign with letsencrypt
}

```

## `etc/doas.conf`
```
permit nopass :wheel

permit nopass _pfbadhost cmd /sbin/pfctl args -nf /etc/pf.conf
permit nopass _pfbadhost cmd /sbin/pfctl args -t pfbadhost -T replace -f /etc/pf-badhost.txt
# Optional rule for authlog scanning
permit nopass _pfbadhost cmd /usr/bin/zcat args -f /var/log/authlog /var/log/authlog.0.gz

```

## `etc/hosts`
```
127.0.0.1 localhost
209.250.248.67 bsdports.net bsdports

```

## `etc/httpd.conf`
```

types {
  include "/usr/share/misc/mime.types"
}

server "bsdports.net" {
  alias "www.bsdports.net"
  listen on localhost port 43718
  location "/.well-known/acme-challenge/*" {
    root "/acme"
    request strip 2
  }
  location "*" {
    block return 301 "https://bsdports.net$REQUEST_URI"
  }
}

server "bsdports.org" {
  alias "www.bsdports.org"
  listen on localhost port 43718
  location "/.well-known/acme-challenge/*" {
    root "/acme"
    request strip 2
  }
  location "*" {
    block return 301 "https://bsdports.org$REQUEST_URI"
  }
}

```

## `etc/pf.conf`
```
ext_if = "vio0"

# Allow all on localhost
set skip on lo

# Block stateless traffic
block return

# Establish keep-state
pass

# Block all incoming by default
block in

# Block bad IPs
# https://www.geoghegan.ca/pfbadhost.html
#
# pfctl -t pfbadhost -T show
# pfctl -t pfbadhost -T flush
# pfctl -t pfbadhost -T add <IP>
# pfctl -t pfbadhost -T delete <IP>
# pfctl -t pfbadhost -T test <IP>
#
table <pfbadhost> persist file "/etc/pf-badhost.txt"
block in quick on $ext_if from <pfbadhost>
block out quick on $ext_if to <pfbadhost>

# Ban brute-force attackers
# http://home.nuug.no/~peter/pf/en/bruteforce.html
#
# pfctl -t bruteforce -T show
# pfctl -t bruteforce -T flush
# pfctl -t bruteforce -T delete <IP>
#
table <bruteforce> persist
block quick from <bruteforce>

# SSH
pass in on $ext_if inet proto tcp from any to $ext_if port 22 keep state (max-src-conn 15, max-src-conn-rate 5/3, overload <bruteforce> flush global)

# DNS
domeneshop = "194.63.248.53"
pass in on $ext_if inet proto { tcp, udp } from $ext_if to $domeneshop port 53 keep state
pass in on $ext_if inet proto { tcp, udp } from any to $ext_if port 53 keep state (max-src-conn 100, max-src-conn-rate 15/5, overload <bruteforce> flush global)

# HTTP/HTTPS
pass in on $ext_if inet proto tcp from any to $ext_if port { 80, 443 } keep state

anchor "relayd/*"

```

## `etc/rc.d/bsdports`
```
#!/bin/ksh

# Rails/Falcon startup script

daemon_user="bsdports"
daemon_execdir="/home/bsdports/bsdports/"
daemon_flags="--config /home/bsdports/bsdports/config.ru --bind http://127.0.0.1:47284"
daemon="/home/bsdports/.local/share/gem/ruby/3.1/bin/falcon31"
daemon_rtable=0

.
<!-- TODO: Break into shorter sentences (455 words > 15) --> /etc/rc.d/rc.subr

pexp="$(eval echo "ruby31: "${daemon}${daemon_flags:+ ${daemon_flags}})"

rc_bg=YES
rc_usercheck=YES

rc_reload=YES
rc_reload_signal=HUP

rc_stop=YES
rc_stop_signal=TERM

# Lets regular users run it
rc_usercheck=YES

rc_start() {
  rc_exec "bundle exec $daemon $daemon_flags"
}

rc_check() {
  pgrep -T "${daemon_rtable}" -q -xf "${pexp}"
}

rc_reload() {
  pkill -${rc_reload_signal} -T "${daemon_rtable}" -xf "${pexp}"
}

rc_stop() {
  pkill -${rc_stop_signal} -T "${daemon_rtable}" -xf "${pexp}"
}

rc_cmd "$1"

```

## `etc/relayd.conf`
```
egress="209.250.248.67"

table <acme_client> { 127.0.0.1 }
acme_client_port="43718"

table <bsdports> { 127.0.0.1 }
bsdports_port="47284"

# --

http protocol "filter_challenge" {
  pass request path "/.well-known/acme-challenge/*" forward to <acme_client>
}

relay "http_relay" {
  listen on $egress port http
  protocol "filter_challenge"
  forward to <acme_client> port $acme_client_port
}

# --

http protocol "falcon" {

  # Preserve IPs for Falcon
  match request header set "X-Forwarded-By" value "$SERVER_ADDR:$SERVER_PORT"    
  match request header set "X-Forwarded-For" value "$REMOTE_ADDR"

  # Best practice security headers
  https://securityheaders.com/
  match response header set "Cache-Control" value "max-age=1814400"
  match response header set "Content-Security-Policy" value "upgrade-insecure-requests; default-src https: 'self'"
  match response header set "Strict-Transport-Security" value "max-age=31536000; includeSubDomains; preload"
  match response header set "Frame-Options" value "SAMEORIGIN"
  match response header set "Referrer-Policy" value "strict-origin"
  match response header set "Feature-Policy" value "accelerometer 'none'; camera 'none'; geolocation 'none'; gyroscope 'none'; magnetometer 'none'; microphone 'none'; payment 'none'; usb 'none'"
  match response header set "X-Content-Type-Options" value "nosniff"
  match response header set "X-Download-Options" value "noopen"
  match response header set "X-Frame-Options" value "SAMEORIGIN"
  match response header set "X-Robots-Tag" value "index, nofollow"
  match response header set "X-XSS-Protection" value "1; mode=block"

  # --

  pass request header "Host" value "bsdports.org" forward to <bsdports>
  pass request header "Host" value "www.bsdports.org" forward to <bsdports>
  tls keypair "bsdports.org"

  pass request header "Host" value "bsdports.net" forward to <bsdports>
  pass request header "Host" value "www.bsdports.net" forward to <bsdports>
  tls keypair "bsdports.net"

  # --

  # Action Cable/StimulusReflex
  http websockets

  # --

  # Brotli compression
  match response header "Accept-Encoding" value "br"
  match response header set "Content-Encoding" value "br"
}

relay "https_relay" {
  listen on $egress port https tls
  protocol "falcon"
  forward to <bsdports> port $bsdports_port
}

```

## `mkcert.sh`
```
#!/usr/bin/env zsh

# GENERATES TLS-CERTIFICATES AND CRONTABS

list=(
  "bsdports.net"
  "bsdports.org"
)

for domain in $list; do
  acme-client -v $domain

  # Check for cert once a week
  # Format: minute hour day-of-month month day-of-week
  (crontab -l; echo "~ ~ * * ~ acme-client $domain && rcctl reload relayd") | crontab -

  sleep 12
done

```

## `var/nsd/etc/nsd.conf`
```
server:
  hide-version: yes
  verbosity: 1

remote-control:
  control-enable: yes
  control-interface: /var/run/nsd.sock

zone:
  name: bsdports.net
  zonefile: master/%s.zone
  notify: 194.63.248.53 NOKEY
  provide-xfr: 194.63.248.53 NOKEY

zone:
  name: bsdports.org
  zonefile: master/%s.zone
  notify: 194.63.248.53 NOKEY
  provide-xfr: 194.63.248.53 NOKEY

```

## `var/nsd/zones/master/bsdports.net.zone`
```
$ORIGIN bsdports.net.
<!-- TODO: Break into shorter sentences (419 words > 15) --> $TTL 24h

@ 1h IN SOA ns.bsdports.net. admin.bsdports.net. (
  2022121201 ; Serial YYYYMMDDnn
  1h         ; Refresh
  15m        ; Retry
  1w         ; Expire
  3m         ; Minimum TTL
)

@ IN NS ns.bsdports.net.
<!-- TODO: Break into shorter sentences (23 words > 15) --> @ IN NS ns.hyp.net. ns IN A 209.250.248.67
ns.hyp.net IN A 194.63.248.53

www IN CNAME @

@ IN A 209.250.248.67

; https://letsencrypt.org/docs/caa/
bsdports.net.
<!-- TODO: Break into shorter sentences (19 words > 15) --> 3m IN CAA 0 issue "letsencrypt.org"

```

## `var/nsd/zones/master/bsdports.org.zone`
```
$ORIGIN bsdports.org. $TTL 24h

@ 1h IN SOA ns.bsdports.net. admin.bsdports.net. (
  2022121201 ; Serial YYYYMMDDnn
  1h         ; Refresh
  15m        ; Retry
  1w         ; Expire
  3m         ; Minimum TTL
)

@ IN NS ns.bsdports.net.
<!-- TODO: Break into shorter sentences (23 words > 15) --> @ IN NS ns.hyp.net. www IN CNAME @

@ IN A 209.250.248.67

; https://letsencrypt.org/docs/caa/
bsdports.org. 3m IN CAA 0 issue "letsencrypt.org"

```
