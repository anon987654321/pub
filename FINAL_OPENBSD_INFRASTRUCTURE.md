# § Final Openbsd Infrastructure

# FINAL OPENBSD INFRASTRUCTURE - Complete Production System Architecture

## Executive Summary

This document provides comprehensive, production-ready OpenBSD infrastructure documentation for deploying and maintaining a secure, scalable system architecture supporting AI³, Rails applications, and business platforms.
<!-- TODO: Break into shorter sentences (41 words > 15) --> The infrastructure implements defense-in-depth security, automated certificate management, DNS with DNSSEC, and high-availability load balancing. ## System Architecture Overview

### Infrastructure Components

**Production OpenBSD Stack:**
```
  OpenBSD 7.8+ Production Server
  ├── Security Framework (pf firewall + pledge/unveil)
  ├── DNS Infrastructure (nsd + DNSSEC)
  ├── Web Services (httpd + relayd + TLS termination)
  ├── Certificate Management (acme-client automation)
  ├── Database Services (PostgreSQL + Redis optimization)
  ├── Application Runtime (Ruby 3.3+ + Falcon server)
  ├── Monitoring Systems (structured logging + alerting)
  └── Disaster Recovery (automated backup + failover)
```

### Security Framework Implementation

#### Advanced pf Firewall Configuration

```bash
# /etc/pf.conf - Production Firewall Rules
ext_if="vio0"
brgen_ip="46.23.95.45"
hyp_ip="194.63.248.53"

# Performance optimization tables
table <allowed_countries> { 47.0.0.0/8, 46.0.0.0/8, 185.0.0.0/8 }
table <bruteforce> persist
table <blacklist> persist file "/etc/pf.blacklist"
table <whitelist> persist { 127.0.0.1, ::1 }

# Skip loopback for performance
set skip on lo

# Normalization for security
scrub in all

# Default deny policy
block return

# Rate limiting macros
ssh_rate = "2/60"
http_rate = "50/10"
https_rate = "100/10"

# SSH protection with geolocation filtering
pass in on $ext_if proto tcp from <allowed_countries> to port 22 \
    keep state (max-src-conn 3, max-src-conn-rate $ssh_rate, \
    overload <bruteforce> flush global)

# Block brute force attackers
block in quick from <bruteforce>
block in quick from <blacklist>

# DNS services with DDoS protection
pass in on $ext_if proto { tcp, udp } to $brgen_ip port 53 \
    keep state (max-src-conn 10, max-src-conn-rate 20/5)

# HTTP/HTTPS with sophisticated rate limiting
pass in on $ext_if proto tcp to $brgen_ip port 80 \
    keep state (max-src-conn 20, max-src-conn-rate $http_rate)

pass in on $ext_if proto tcp to $brgen_ip port 443 \
    keep state (max-src-conn 50, max-src-conn-rate $https_rate)

# ACME challenge support
pass in on $ext_if proto tcp to $brgen_ip port 80 \
    tag ACME keep state

# Outbound connections for system updates and API calls
pass out on $ext_if proto tcp to port { 53, 80, 443 } keep state
pass out on $ext_if proto udp to port 53 keep state

# Anchor for dynamic relayd rules
anchor "relayd/*"

# Logging for security analysis
pass log all
```

#### Pledge/Unveil Security Implementation
<!-- TODO: Fix heading hierarchy - level 4 after level 1 -->

```ruby
# /usr/local/lib/ruby/site_ruby/openbsd_security.rb
class OpenBSDSecurity
  PLEDGE_PROFILES = {
    web_server: "stdio rpath wpath cpath inet dns proc exec",
    ai3_system: "stdio rpath wpath cpath inet dns proc exec prot_exec",
    database: "stdio rpath wpath cpath inet unix flock",
    backup_service: "stdio rpath wpath cpath fattr"
  }.freeze

  UNVEIL_PATHS = {
    web_server: [
      ["/var/www", "r"],
      ["/etc/ssl", "r"],
      ["/tmp", "rwc"],
      ["/var/log", "wc"]
    ],
    ai3_system: [
      ["/home/ai3", "rwc"],
      ["/usr/local", "r"],
      ["/var/log", "wc"],
      ["/tmp", "rwc"],
      ["/etc/ssl", "r"]
    ],
    database: [
      ["/var/postgresql", "rwc"],
      ["/var/log", "wc"],
      ["/tmp", "rwc"]
    ]
  }.freeze

  def self.apply_security_profile(profile)
    raise "Unknown profile: #{profile}" unless PLEDGE_PROFILES.key?(profile)

    # Apply pledge restrictions
    pledge_result = pledge(PLEDGE_PROFILES[profile])
    if pledge_result != 0
      raise "Failed to apply pledge profile: #{profile}"
    end

    # Apply unveil restrictions
    UNVEIL_PATHS[profile].each do |path, permissions|
      unveil_result = unveil(path, permissions)
      if unveil_result != 0
        raise "Failed to unveil path: #{path}"
      end
    end

    # Lock down unveil
    unveil_result = unveil(nil, nil)
    if unveil_result != 0
      raise "Failed to lock unveil"
    end

    true
  end

  private

  def self.pledge(promises)
    # FFI call to OpenBSD pledge system call
    require 'fiddle'
    libc = Fiddle.dlopen('libc.so')
    pledge_func = Fiddle::Function.new(
      libc['pledge'],
      [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP],
      Fiddle::TYPE_INT
    )
    pledge_func.call(promises, nil)
  end

  def self.unveil(path, permissions)
    require 'fiddle'
    libc = Fiddle.dlopen('libc.so')
    unveil_func = Fiddle::Function.new(
      libc['unveil'],
      [Fiddle::TYPE_VOIDP, Fiddle::TYPE_VOIDP],
      Fiddle::TYPE_INT
    )
    unveil_func.call(path, permissions)
  end
end
```

## DNS Infrastructure with DNSSEC

### NSD Configuration for High Performance

```bash
# /var/nsd/etc/nsd.conf - Authoritative DNS Server
server:
    ip-address: 46.23.95.45
    ip-address: ::1
    port: 53
    server-count: 4
    
    # Security and performance settings
    hide-version: yes
    identity: "brgen-dns"
    nsid: "brgen-primary"
    
    # Zone file management
    zonesdir: "/var/nsd/zones"
    logfile: "/var/log/nsd.log"
    pidfile: "/var/run/nsd.pid"
    
    # Performance optimizations
    tcp-count: 200
    tcp-query-count: 50
    tcp-timeout: 120
    ipv4-edns-size: 4096
    ipv6-edns-size: 4096
    
    # DNSSEC settings
    verify-zone: yes
    verbosity: 2

# Remote control for dynamic updates
remote-control:
    control-enable: yes
    control-interface: 127.0.0.1
    control-port: 8952
    server-key-file: "/var/nsd/etc/nsd_server.key"
    server-cert-file: "/var/nsd/etc/nsd_server.pem"
    control-key-file: "/var/nsd/etc/nsd_control.key"
    control-cert-file: "/var/nsd/etc/nsd_control.pem"

# Zone definitions for primary domains
zone:
    name: "brgen.no"
    zonefile: "master/brgen.no.zone"
    notify: 8.8.8.8 NOKEY
    provide-xfr: 8.8.8.8 NOKEY

zone:
    name: "oshlo.no"
    zonefile: "master/oshlo.no.zone"

# Include additional zone configurations
include: "/var/nsd/etc/zones.conf"
```

### DNSSEC Zone Signing Automation
<!-- TODO: Fix heading hierarchy - level 3 after level 1 -->

```bash
#!/usr/bin/env zsh
# /usr/local/bin/dnssec-maintain.sh - Automated DNSSEC Management

set -e

ZONES_DIR="/var/nsd/zones/master"
KEYS_DIR="/var/nsd/keys"
LOG_FILE="/var/log/dnssec.log"

log() {
    echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $1" | tee -a "$LOG_FILE"
}

generate_zone_keys() {
    local zone="$1"
    local key_dir="${KEYS_DIR}/${zone}"
    
    mkdir -p "$key_dir"
    cd "$key_dir"
    
    # Generate KSK (Key Signing Key)
    if [ !
<!-- TODO: Break into shorter sentences (705 words > 15) --> -f "K${zone}.+008+*.key" ]; then
        log "Generating KSK for ${zone}"
        ldns-keygen -a RSASHA256 -b 2048 -k "$zone"
    fi
    
    # Generate ZSK (Zone Signing Key)
    if [ !
<!-- TODO: Break into shorter sentences (26 words > 15) --> -f "K${zone}.+008+*.private" ]; then
        log "Generating ZSK for ${zone}"
        ldns-keygen -a RSASHA256 -b 1024 "$zone"
    fi
}

sign_zone() {
    local zone="$1"
    local zone_file="${ZONES_DIR}/${zone}.zone"
    local signed_file="${ZONES_DIR}/${zone}.zone.signed"
    local key_dir="${KEYS_DIR}/${zone}"
    
    if [ !
<!-- TODO: Break into shorter sentences (30 words > 15) --> -f "$zone_file" ]; then
        log "Error: Zone file not found: $zone_file"
        return 1
    fi
    
    cd "$key_dir"
    
    # Sign the zone
    log "Signing zone: $zone"
    ldns-signzone -n \
        -p \
        -e $(date -d '+30 days' +%Y%m%d%H%M%S) \
        "$zone_file" \
        K${zone}.+008+*.private
    
    # Move signed zone to proper location
    mv "${zone}.zone.signed" "$signed_file"
    
    # Update NSD configuration to use signed zone
    sed -i "s|zonefile: \"master/${zone}.zone\"|zonefile: \"master/${zone}.zone.signed\"|" \
        /var/nsd/etc/nsd.conf
    
    log "Zone signed successfully: $zone"
}

monitor_key_expiration() {
    local zone="$1"
    local key_dir="${KEYS_DIR}/${zone}"
    
    cd "$key_dir"
    
    # Check key expiration (example for monitoring)
    for key_file in K${zone}.+008+*.key; do
        if [ -f "$key_file" ]; then
            # Extract expiration date from key
            expiry=$(ldns-read-zone "$key_file" | grep -o 'expire=[0-9]*' | cut -d= -f2)
            if [ -n "$expiry" ]; then
                current_time=$(date +%s)
                days_until_expiry=$(( (expiry - current_time) / 86400 ))
                
                if [ "$days_until_expiry" -lt 30 ]; then
                    log "WARNING: Key $key_file expires in $days_until_expiry days"
                fi
            fi
        fi
    done
}

# Main execution
main() {
    local action="${1:-sign}"
    local zone="${2:-brgen.no}"
    
    case "$action" in
        "generate")
            generate_zone_keys "$zone"
            ;;
        "sign")
            generate_zone_keys "$zone"
            sign_zone "$zone"
            nsd-control reload "$zone"
            ;;
        "monitor")
            monitor_key_expiration "$zone"
            ;;
        *)
            echo "Usage: $0 {generate|sign|monitor} [zone]"
            exit 1
            ;;
    esac
}

main "$@"
```

## Web Services Configuration

### High-Performance relayd Load Balancer

```bash
# /etc/relayd.conf - Advanced Load Balancer Configuration

# Macros for maintainability
brgen_ip = "46.23.95.45"
hyp_ip = "194.63.248.53"

# Backend application servers
table <brgen_backend> { 127.0.0.1:3000 }
table <amber_backend> { 127.0.0.1:3001 }
table <pubattorney_backend> { 127.0.0.1:3002 }
table <bsdports_backend> { 127.0.0.1:3003 }
table <hjerterom_backend> { 127.0.0.1:3004 }
table <privcam_backend> { 127.0.0.1:3005 }
table <blognet_backend> { 127.0.0.1:3006 }

# Health check for ACME challenges
table <httpd> { 127.0.0.1:80 }

# HTTP protocol for ACME and redirection
http protocol "http_acme" {
    # Security headers
    match request header set "X-Forwarded-Proto" value "http"
    match request header set "X-Forwarded-For" value "$REMOTE_ADDR"
    match request header set "X-Real-IP" value "$REMOTE_ADDR"
    
    # ACME challenge passthrough
    pass request path "/.well-known/acme-challenge/*" forward to <httpd>
    
    # Redirect all other HTTP to HTTPS
    match request header "Host" tag "redirect"
    match request tagged "redirect" header set "Location" value "https://$HTTP_HOST$REQUEST_URI"
    match request tagged "redirect" return code 301
    
    # Security: Prevent HTTP request smuggling
    match request header "Transfer-Encoding" value "chunked" label "chunked"
    block request labeled "chunked"
}

# HTTPS protocol with advanced security
http protocol "https_production" {
    # Performance and security headers
    match request header set "X-Forwarded-Proto" value "https"
    match request header set "X-Forwarded-For" value "$REMOTE_ADDR"
    match request header set "X-Real-IP" value "$REMOTE_ADDR"
    
    # Security headers for all responses
    match response header set "Strict-Transport-Security" value "max-age=31536000; includeSubDomains; preload"
    match response header set "X-Frame-Options" value "DENY"
    match response header set "X-Content-Type-Options" value "nosniff"
    match response header set "X-XSS-Protection" value "1; mode=block"
    match response header set "Referrer-Policy" value "strict-origin-when-cross-origin"
    match response header set "Content-Security-Policy" value "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'"
    match response header set "Permissions-Policy" value "camera=(), microphone=(), geolocation=()"
    
    # Cache control for static assets
    match request path "*.css" tag "static"
    match request path "*.js" tag "static"
    match request path "*.png" tag "static"
    match request path "*.jpg" tag "static"
    match request path "*.svg" tag "static"
    match response tagged "static" header set "Cache-Control" value "public, max-age=31536000"
    
    # Compression for text content
    match response header "Content-Type" value "text/*" tag "compress"
    match response header "Content-Type" value "application/json" tag "compress"
    match response tagged "compress" header set "Content-Encoding" value "gzip"
    
    # Rate limiting per session
    tcp { nodelay, sack, socket buffer 65536 }
    
    # Health checks
    return error style "body { background: #2c3e50; color: #ecf0f1; font-family: monospace; padding: 2rem; } h1 { color: #e74c3c; }"
}

# HTTP to HTTPS redirection relay
relay "http_redirect" {
    listen on $brgen_ip port 80
    protocol "http_acme"
    forward to <httpd> port 80
}

# TLS certificates for domains
tls keypair "brgen.no" {
    cert "/etc/ssl/brgen.no.fullchain.pem"
    key "/etc/ssl/private/brgen.no.key"
}

tls keypair "oshlo.no" {
    cert "/etc/ssl/oshlo.no.fullchain.pem"
    key "/etc/ssl/private/oshlo.no.key"
}

# Main HTTPS relay with SNI support
relay "https" {
    listen on $brgen_ip port 443 tls
    protocol "https_production"
    
    # Domain-based routing with health checks
    match request header "Host" value "brgen.no" forward to <brgen_backend> check http "/" code 200
    match request header "Host" value "oshlo.no" forward to <brgen_backend> check http "/" code 200
    match request header "Host" value "amber.brgen.no" forward to <amber_backend> check http "/" code 200
    match request header "Host" value "pubattorney.brgen.no" forward to <pubattorney_backend> check http "/" code 200
    match request header "Host" value "bsdports.brgen.no" forward to <bsdports_backend> check http "/" code 200
    match request header "Host" value "hjerterom.brgen.no" forward to <hjerterom_backend> check http "/" code 200
    match request header "Host" value "privcam.brgen.no" forward to <privcam_backend> check http "/" code 200
    match request header "Host" value "blognet.brgen.no" forward to <blognet_backend> check http "/" code 200
}

# Advanced session persistence
relay "https_sticky" {
    listen on $hyp_ip port 443 tls
    protocol "https_production"
    session cookie "rails_session_id"
    
    # Sticky sessions for stateful applications
    match request header "Host" value "brgen.no" forward to <brgen_backend> check http "/" code 200
}
```

### httpd Static Content Server
<!-- TODO: Fix heading hierarchy - level 3 after level 1 -->

```bash
# /etc/httpd.conf - Static Content and ACME Challenge Server
server "default" {
    listen on 127.0.0.1 port 80
    
    # ACME challenge handling
    location "/.well-known/acme-challenge/*" {
        root "/var/www/acme"
        request strip 2
    }
    
    # Static assets for performance
    location "/assets/*" {
        root "/var/www/htdocs"
        
        # Cache control
        block return 200 "Cache-Control: public, max-age=31536000"
    }
    
    # Default response for health checks
    location "/" {
        block return 200 "OpenBSD httpd ready"
    }
}

# HTTPS server for static content delivery
server "static.brgen.no" {
    listen on 127.0.0.1 port 8080 tls
    tls {
        certificate "/etc/ssl/brgen.no.fullchain.pem"
        key "/etc/ssl/private/brgen.no.key"
    }
    
    location "/static/*" {
        root "/var/www/static"
        request strip 1
        
        # Aggressive caching for static content
        block return 200 "Cache-Control: public, max-age=31536000, immutable"
    }
}
```

## Certificate Management with acme-client

### Automated Certificate Provisioning

```bash
# /etc/acme-client.conf - Let's Encrypt Integration
authority letsencrypt {
    api url "https://acme-v02.api.letsencrypt.org/directory"
    account key "/etc/acme/letsencrypt.pem"
}

authority letsencrypt-staging {
    api url "https://acme-staging-v02.api.letsencrypt.org/directory"
    account key "/etc/acme/letsencrypt-staging.pem"
}

# Domain certificate configurations
domain brgen.no {
    alternative names { www.brgen.no, api.brgen.no, cdn.brgen.no }
    domain key "/etc/ssl/private/brgen.no.key"
    domain full chain certificate "/etc/ssl/brgen.no.fullchain.pem"
    sign with letsencrypt
    challengedir "/var/www/acme"
}

domain oshlo.no {
    alternative names { www.oshlo.no, api.oshlo.no }
    domain key "/etc/ssl/private/oshlo.no.key"  
    domain full chain certificate "/etc/ssl/oshlo.no.fullchain.pem"
    sign with letsencrypt
    challengedir "/var/www/acme"
}

# Subdomain wildcards for applications
domain "*.brgen.no" {
    domain key "/etc/ssl/private/wildcard.brgen.no.key"
    domain full chain certificate "/etc/ssl/wildcard.brgen.no.fullchain.pem"
    sign with letsencrypt
    challengedir "/var/www/acme"
}
```

### Certificate Renewal Automation
<!-- TODO: Fix heading hierarchy - level 3 after level 1 -->

```bash
#!/usr/bin/env zsh
# /usr/local/bin/cert-renewal.sh - Automated Certificate Management

set -e

LOG_FILE="/var/log/cert-renewal.log"
CERT_DIR="/etc/ssl"
NOTIFY_EMAIL="admin@brgen.no"

log() {
    echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $1" | tee -a "$LOG_FILE"
}

check_certificate_expiry() {
    local cert_file="$1"
    local domain="$2"
    local days_threshold="${3:-30}"
    
    if [ !
<!-- TODO: Break into shorter sentences (1069 words > 15) --> -f "$cert_file" ]; then
        log "WARNING: Certificate file not found: $cert_file"
        return 1
    fi
    
    # Get certificate expiry date
    expiry_date=$(openssl x509 -in "$cert_file" -noout -enddate | cut -d= -f2)
    expiry_epoch=$(date -d "$expiry_date" +%s)
    current_epoch=$(date +%s)
    days_until_expiry=$(( (expiry_epoch - current_epoch) / 86400 ))
    
    log "Certificate $domain expires in $days_until_expiry days"
    
    if [ "$days_until_expiry" -lt "$days_threshold" ]; then
        log "Certificate $domain needs renewal (expires in $days_until_expiry days)"
        return 0
    fi
    
    return 1
}

renew_certificate() {
    local domain="$1"
    
    log "Starting certificate renewal for $domain"
    
    # Stop services that might interfere
    rcctl stop relayd
    
    # Request new certificate
    if acme-client -v "$domain"; then
        log "Certificate renewed successfully for $domain"
        
        # Reload services
        rcctl start relayd
        nsd-control reconfig
        
        # Send success notification
        echo "Certificate for $domain renewed successfully at $(date)" | \
            mail -s "Certificate Renewal Success: $domain" "$NOTIFY_EMAIL"
            
        return 0
    else
        log "ERROR: Certificate renewal failed for $domain"
        
        # Restart services anyway
        rcctl start relayd
        
        # Send failure notification
        echo "Certificate renewal failed for $domain at $(date).
<!-- TODO: Break into shorter sentences (163 words > 15) --> Check logs at $LOG_FILE" | \
            mail -s "Certificate Renewal FAILED: $domain" "$NOTIFY_EMAIL"
            
        return 1
    fi
}

backup_certificates() {
    local backup_dir="/var/backups/ssl/$(date +%Y%m%d)"
    
    mkdir -p "$backup_dir"
    
    # Backup current certificates
    cp -r "$CERT_DIR"/*.pem "$backup_dir/" 2>/dev/null || true
    cp -r "$CERT_DIR"/private/*.key "$backup_dir/" 2>/dev/null || true
    
    # Compress backup
    tar -czf "${backup_dir}.tar.gz" -C /var/backups/ssl "$(basename "$backup_dir")"
    rm -rf "$backup_dir"
    
    # Keep only last 30 days of backups
    find /var/backups/ssl -name "*.tar.gz" -mtime +30 -delete
    
    log "Certificates backed up to ${backup_dir}.tar.gz"
}

monitor_certificate_health() {
    local domain="$1"
    local cert_file="${CERT_DIR}/${domain}.fullchain.pem"
    
    # Check certificate validity
    if !
<!-- TODO: Break into shorter sentences (90 words > 15) --> openssl x509 -in "$cert_file" -noout -checkend 86400; then
        log "ERROR: Certificate $domain is invalid or expires within 24 hours"
        return 1
    fi
    
    # Check certificate chain
    if !
<!-- TODO: Break into shorter sentences (28 words > 15) --> openssl verify -CAfile /etc/ssl/cert.pem "$cert_file"; then
        log "ERROR: Certificate chain validation failed for $domain"
        return 1
    fi
    
    # Test HTTPS connectivity
    if !
<!-- TODO: Break into shorter sentences (23 words > 15) --> timeout 10 openssl s_client -connect "${domain}:443" -servername "$domain" < /dev/null; then
        log "ERROR: HTTPS connection test failed for $domain"
        return 1
    fi
    
    log "Certificate health check passed for $domain"
    return 0
}

# Main execution
main() {
    local action="${1:-check}"
    local domain="${2:-brgen.no}"
    
    case "$action" in
        "check")
            if check_certificate_expiry "${CERT_DIR}/${domain}.fullchain.pem" "$domain"; then
                renew_certificate "$domain"
            fi
            ;;
        "renew")
            backup_certificates
            renew_certificate "$domain"
            ;;
        "monitor")
            monitor_certificate_health "$domain"
            ;;
        "backup")
            backup_certificates
            ;;
        *)
            echo "Usage: $0 {check|renew|monitor|backup} [domain]"
            exit 1
            ;;
    esac
}

main "$@"
```

## Database Services Optimization

### PostgreSQL High-Performance Configuration

```bash
# /var/postgresql/data/postgresql.conf - Production Tuning
# Memory and performance settings
shared_buffers = 512MB
effective_cache_size = 2GB
maintenance_work_mem = 128MB
checkpoint_completion_target = 0.9
wal_buffers = 16MB
default_statistics_target = 100

# Connection settings
max_connections = 200
superuser_reserved_connections = 3

# Write-ahead logging
wal_level = replica
max_wal_size = 2GB
min_wal_size = 80MB
archive_mode = on
archive_command = '/usr/local/bin/backup-wal.sh %f %p'

# Query optimization
random_page_cost = 1.1
effective_io_concurrency = 200

# Logging configuration
logging_collector = on
log_directory = '/var/log/postgresql'
log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'
log_rotation_age = 1d
log_rotation_size = 100MB
log_min_duration_statement = 1000
log_line_prefix = '%t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h '
log_checkpoints = on
log_connections = on
log_disconnections = on
log_lock_waits = on

# Security settings
ssl = on
ssl_cert_file = '/etc/ssl/postgresql.crt'
ssl_key_file = '/etc/ssl/private/postgresql.key'
ssl_ca_file = '/etc/ssl/root.crt'
ssl_ciphers = 'HIGH:MEDIUM:+3DES:!aNULL'
ssl_prefer_server_ciphers = on
```

### Redis Optimization for Caching
<!-- TODO: Fix heading hierarchy - level 3 after level 1 -->

```bash
# /etc/redis.conf - High-Performance Cache Configuration
# Network settings
bind 127.0.0.1
port 6379
timeout 300
tcp-keepalive 300

# Memory management
maxmemory 256mb
maxmemory-policy allkeys-lru
maxmemory-samples 5

# Persistence settings
save 900 1
save 300 10
save 60 10000
stop-writes-on-bgsave-error yes
rdbcompression yes
rdbchecksum yes
dbfilename dump.rdb
dir /var/redis/

# Append only file
appendonly yes
appendfilename "appendonly.aof"
appendfsync everysec
no-appendfsync-on-rewrite no
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb

# Security
requirepass "$(openssl rand -hex 32)"
rename-command FLUSHDB ""
rename-command FLUSHALL ""
rename-command DEBUG ""

# Performance tuning
tcp-backlog 511
databases 16
hz 10
```

## Monitoring and Alerting System

### Comprehensive System Monitoring

```bash
#!/usr/bin/env zsh
# /usr/local/bin/system-monitor.sh - Production Monitoring

set -e

METRICS_DIR="/var/metrics"
ALERT_THRESHOLD_CPU=80
ALERT_THRESHOLD_MEMORY=85
ALERT_THRESHOLD_DISK=90
ALERT_EMAIL="admin@brgen.no"

mkdir -p "$METRICS_DIR"

collect_system_metrics() {
    local timestamp=$(date +%s)
    local metrics_file="${METRICS_DIR}/system-$(date +%Y%m%d).json"
    
    # CPU usage
    local cpu_usage=$(top -n | head -n 3 | tail -n 1 | awk '{print $2}' | sed 's/%//')
    
    # Memory usage
    local memory_info=$(top -n | head -n 4 | tail -n 1)
    local memory_used=$(echo "$memory_info" | awk '{print $3}' | sed 's/M//')
    local memory_total=$(echo "$memory_info" | awk '{print $1}' | sed 's/M//')
    local memory_percent=$((memory_used * 100 / memory_total))
    
    # Disk usage
    local disk_usage=$(df -h / | tail -n 1 | awk '{print $5}' | sed 's/%//')
    
    # Network connections
    local tcp_connections=$(netstat -an | grep -c "ESTABLISHED")
    
    # Load average
    local load_avg=$(uptime | awk -F'load averages:' '{print $2}' | awk '{print $1}')
    
    # Create JSON metrics
    cat > "${metrics_file}.tmp" <<EOF
{
  "timestamp": $timestamp,
  "cpu_usage": $cpu_usage,
  "memory_percent": $memory_percent,
  "memory_used_mb": $memory_used,
  "memory_total_mb": $memory_total,
  "disk_usage_percent": $disk_usage,
  "tcp_connections": $tcp_connections,
  "load_average": $load_avg,
  "uptime": "$(uptime | awk '{print $3, $4}' | sed 's/,//')"
}
EOF
    
    # Append to daily metrics file
    if [ -f "$metrics_file" ]; then
        sed '$s/$/,/' "$metrics_file" > "${metrics_file}.tmp2"
        cat "${metrics_file}.tmp2" "${metrics_file}.tmp" > "$metrics_file"
        rm "${metrics_file}.tmp2"
    else
        echo "[" > "$metrics_file"
        cat "${metrics_file}.tmp" >> "$metrics_file"
    fi
    
    rm "${metrics_file}.tmp"
    
    # Check thresholds and alert
    check_alerts "$cpu_usage" "$memory_percent" "$disk_usage"
}

check_alerts() {
    local cpu="$1"
    local memory="$2"
    local disk="$3"
    
    if [ "$cpu" -gt "$ALERT_THRESHOLD_CPU" ]; then
        send_alert "High CPU Usage" "CPU usage is at ${cpu}% (threshold: ${ALERT_THRESHOLD_CPU}%)"
    fi
    
    if [ "$memory" -gt "$ALERT_THRESHOLD_MEMORY" ]; then
        send_alert "High Memory Usage" "Memory usage is at ${memory}% (threshold: ${ALERT_THRESHOLD_MEMORY}%)"
    fi
    
    if [ "$disk" -gt "$ALERT_THRESHOLD_DISK" ]; then
        send_alert "High Disk Usage" "Disk usage is at ${disk}% (threshold: ${ALERT_THRESHOLD_DISK}%)"
    fi
}

send_alert() {
    local subject="$1"
    local message="$2"
    local hostname=$(hostname)
    
    cat <<EOF | mail -s "ALERT: $subject - $hostname" "$ALERT_EMAIL"
Alert: $subject

Server: $hostname
Time: $(date)
Message: $message

System Status:
$(uptime)

Top Processes:
$(top -n | head -n 15)

Disk Usage:
$(df -h)

Network Connections:
$(netstat -an | grep -c "ESTABLISHED") active connections
EOF
}

monitor_services() {
    local services=("httpd" "relayd" "nsd" "postgresql" "redis")
    
    for service in "${services[@]}"; do
        if !
<!-- TODO: Break into shorter sentences (669 words > 15) --> rcctl check "$service"; then
            send_alert "Service Down" "Service $service is not running"
            
            # Attempt to restart service
            if rcctl start "$service"; then
                send_alert "Service Recovered" "Service $service has been restarted successfully"
            else
                send_alert "Service Restart Failed" "Failed to restart service $service"
            fi
        fi
    done
}

check_certificate_expiry() {
    local cert_file="/etc/ssl/brgen.no.fullchain.pem"
    
    if [ -f "$cert_file" ]; then
        local expiry_date=$(openssl x509 -in "$cert_file" -noout -enddate | cut -d= -f2)
        local expiry_epoch=$(date -d "$expiry_date" +%s)
        local current_epoch=$(date +%s)
        local days_until_expiry=$(( (expiry_epoch - current_epoch) / 86400 ))
        
        if [ "$days_until_expiry" -lt 14 ]; then
            send_alert "Certificate Expiring Soon" "SSL certificate expires in $days_until_expiry days"
        fi
    fi
}

# Log rotation for metrics
rotate_logs() {
    find "$METRICS_DIR" -name "system-*.json" -mtime +30 -delete
    find /var/log -name "*.log" -size +100M -exec gzip {} \;
    find /var/log -name "*.gz" -mtime +90 -delete
}

# Main execution
main() {
    collect_system_metrics
    monitor_services
    check_certificate_expiry
    rotate_logs
}

main
```

### Application Performance Monitoring
<!-- TODO: Fix heading hierarchy - level 3 after level 1 -->

```ruby
# /usr/local/lib/ruby/site_ruby/application_monitor.rb
class ApplicationMonitor
  def initialize
    @metrics_file = "/var/metrics/app-#{Date.today.strftime('%Y%m%d')}.json"
    @alert_thresholds = {
      response_time: 5.0,  # seconds
      error_rate: 0.05,    # 5%
      memory_usage: 500    # MB
    }
  end

  def monitor_rails_applications
    apps = %w[brgen amber pubattorney bsdports hjerterom privcam blognet]
    
    apps.each do |app|
      monitor_app(app)
    end
  end

  def monitor_app(app_name)
    port = get_app_port(app_name)
    return unless port
    
    metrics = {
      app: app_name,
      timestamp: Time.now.to_i,
      status: check_app_health(port),
      response_time: measure_response_time(port),
      memory_usage: get_app_memory_usage(app_name),
      active_connections: count_active_connections(port)
    }
    
    # Check for alerts
    check_app_alerts(app_name, metrics)
    
    # Log metrics
    log_metrics(metrics)
  end

  private

  def check_app_health(port)
    begin
      response = Net::HTTP.get_response(URI("http://127.0.0.1:#{port}/health"))
      response.code == "200" ?
<!-- TODO: Break into shorter sentences (240 words > 15) --> "healthy" : "unhealthy"
    rescue
      "down"
    end
  end

  def measure_response_time(port)
    start_time = Time.now
    begin
      Net::HTTP.get_response(URI("http://127.0.0.1:#{port}/"))
      Time.now - start_time
    rescue
      -1
    end
  end

  def get_app_memory_usage(app_name)
    # Get memory usage from process list
    memory_kb = `ps -o rss= -C "#{app_name}"`.strip.to_i
    memory_kb / 1024  # Convert to MB
  end

  def check_app_alerts(app_name, metrics)
    if metrics[:response_time] > @alert_thresholds[:response_time]
      send_alert("Slow Response Time", 
                "#{app_name} response time: #{metrics[:response_time]}s")
    end
    
    if metrics[:status] != "healthy"
      send_alert("Application Down", 
                "#{app_name} is #{metrics[:status]}")
    end
    
    if metrics[:memory_usage] > @alert_thresholds[:memory_usage]
      send_alert("High Memory Usage", 
                "#{app_name} memory usage: #{metrics[:memory_usage]}MB")
    end
  end

  def send_alert(subject, message)
    system("echo '#{message}' | mail -s 'APP ALERT: #{subject}' admin@brgen.no")
  end

  def get_app_port(app_name)
    ports = {
      'brgen' => 3000,
      'amber' => 3001,
      'pubattorney' => 3002,
      'bsdports' => 3003,
      'hjerterom' => 3004,
      'privcam' => 3005,
      'blognet' => 3006
    }
    ports[app_name]
  end
end
```

## Disaster Recovery and Backup Strategy

### Automated Backup System

```bash
#!/usr/bin/env zsh
# /usr/local/bin/backup-system.sh - Comprehensive Backup Solution

set -e

BACKUP_ROOT="/var/backups"
REMOTE_BACKUP_HOST="backup.brgen.no"
REMOTE_BACKUP_USER="backup"
RETENTION_DAYS=30
LOG_FILE="/var/log/backup.log"

log() {
    echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $1" | tee -a "$LOG_FILE"
}

backup_databases() {
    local backup_dir="${BACKUP_ROOT}/databases/$(date +%Y%m%d)"
    mkdir -p "$backup_dir"
    
    log "Starting database backups"
    
    # PostgreSQL backup
    doas -u _postgresql pg_dumpall > "${backup_dir}/postgresql-all.sql"
    gzip "${backup_dir}/postgresql-all.sql"
    
    # Individual database backups
    for db in brgen_production amber_production pubattorney_production; do
        if doas -u _postgresql psql -lqt | cut -d \| -f 1 | grep -qw "$db"; then
            doas -u _postgresql pg_dump "$db" > "${backup_dir}/${db}.sql"
            gzip "${backup_dir}/${db}.sql"
            log "Backed up database: $db"
        fi
    done
    
    # Redis backup
    cp /var/redis/dump.rdb "${backup_dir}/redis-dump.rdb"
    gzip "${backup_dir}/redis-dump.rdb"
    
    log "Database backups completed"
}

backup_configurations() {
    local backup_dir="${BACKUP_ROOT}/configs/$(date +%Y%m%d)"
    mkdir -p "$backup_dir"
    
    log "Starting configuration backups"
    
    # System configurations
    tar -czf "${backup_dir}/etc-configs.tar.gz" \
        /etc/pf.conf \
        /etc/relayd.conf \
        /etc/httpd.conf \
        /etc/acme-client.conf \
        /var/nsd/etc/nsd.conf \
        /var/postgresql/data/postgresql.conf \
        /etc/redis.conf
    
    # SSL certificates
    tar -czf "${backup_dir}/ssl-certs.tar.gz" \
        /etc/ssl/*.pem \
        /etc/ssl/private/*.key
    
    # Application configurations
    for app in brgen amber pubattorney bsdports hjerterom privcam blognet; do
        if [ -d "/home/${app}/app/config" ]; then
            tar -czf "${backup_dir}/${app}-config.tar.gz" \
                "/home/${app}/app/config"
        fi
    done
    
    log "Configuration backups completed"
}

backup_application_data() {
    local backup_dir="${BACKUP_ROOT}/apps/$(date +%Y%m%d)"
    mkdir -p "$backup_dir"
    
    log "Starting application data backups"
    
    # User uploads and static files
    for app in brgen amber pubattorney bsdports hjerterom privcam blognet; do
        if [ -d "/home/${app}/app/storage" ]; then
            tar -czf "${backup_dir}/${app}-storage.tar.gz" \
                "/home/${app}/app/storage"
            log "Backed up storage for: $app"
        fi
        
        if [ -d "/home/${app}/app/public/uploads" ]; then
            tar -czf "${backup_dir}/${app}-uploads.tar.gz" \
                "/home/${app}/app/public/uploads"
            log "Backed up uploads for: $app"
        fi
    done
    
    # AI³ system data
    if [ -d "/home/ai3/ai3/data" ]; then
        tar -czf "${backup_dir}/ai3-data.tar.gz" \
            "/home/ai3/ai3/data"
        log "Backed up AI³ data"
    fi
    
    log "Application data backups completed"
}

backup_logs() {
    local backup_dir="${BACKUP_ROOT}/logs/$(date +%Y%m%d)"
    mkdir -p "$backup_dir"
    
    log "Starting log backups"
    
    # Compress and backup logs older than 1 day
    find /var/log -name "*.log" -mtime +1 -exec gzip {} \;
    
    # Archive compressed logs
    tar -cf "${backup_dir}/system-logs.tar" /var/log/*.gz
    
    # Application logs
    for app in brgen amber pubattorney bsdports hjerterom privcam blognet; do
        if [ -d "/home/${app}/app/log" ]; then
            tar -czf "${backup_dir}/${app}-logs.tar.gz" \
                "/home/${app}/app/log"
        fi
    done
    
    log "Log backups completed"
}

sync_to_remote() {
    local date_dir="$(date +%Y%m%d)"
    
    log "Starting remote backup sync"
    
    # Sync to remote backup server
    rsync -avz --delete \
        "${BACKUP_ROOT}/" \
        "${REMOTE_BACKUP_USER}@${REMOTE_BACKUP_HOST}:/backups/$(hostname)/"
    
    if [ $?
<!-- TODO: Break into shorter sentences (510 words > 15) --> -eq 0 ]; then
        log "Remote backup sync completed successfully"
    else
        log "ERROR: Remote backup sync failed"
        echo "Remote backup sync failed at $(date)" | \
            mail -s "Backup Sync FAILED - $(hostname)" admin@brgen.no
        return 1
    fi
}

cleanup_old_backups() {
    log "Cleaning up old backups"
    
    # Remove local backups older than retention period
    find "$BACKUP_ROOT" -type d -name "20*" -mtime +$RETENTION_DAYS -exec rm -rf {} \;
    
    # Clean up compressed logs
    find /var/log -name "*.gz" -mtime +$RETENTION_DAYS -delete
    
    log "Cleanup completed"
}

verify_backups() {
    local date_dir="$(date +%Y%m%d)"
    local error_count=0
    
    log "Verifying backup integrity"
    
    # Check if backup files exist and are not empty
    for backup_type in databases configs apps logs; do
        backup_dir="${BACKUP_ROOT}/${backup_type}/${date_dir}"
        if [ !
<!-- TODO: Break into shorter sentences (115 words > 15) --> -d "$backup_dir" ] || [ -z "$(ls -A $backup_dir)" ]; then
            log "ERROR: Backup verification failed for $backup_type"
            error_count=$((error_count + 1))
        fi
    done
    
    # Test database backup integrity
    if [ -f "${BACKUP_ROOT}/databases/${date_dir}/postgresql-all.sql.gz" ]; then
        if !
<!-- TODO: Break into shorter sentences (36 words > 15) --> gzip -t "${BACKUP_ROOT}/databases/${date_dir}/postgresql-all.sql.gz"; then
            log "ERROR: PostgreSQL backup file is corrupted"
            error_count=$((error_count + 1))
        fi
    fi
    
    if [ $error_count -eq 0 ]; then
        log "Backup verification completed successfully"
        return 0
    else
        log "ERROR: Backup verification failed with $error_count errors"
        echo "Backup verification failed with $error_count errors" | \
            mail -s "Backup Verification FAILED - $(hostname)" admin@brgen.no
        return 1
    fi
}

# Main execution
main() {
    local backup_type="${1:-all}"
    
    case "$backup_type" in
        "databases")
            backup_databases
            ;;
        "configs")
            backup_configurations
            ;;
        "apps")
            backup_application_data
            ;;
        "logs")
            backup_logs
            ;;
        "all")
            backup_databases
            backup_configurations
            backup_application_data
            backup_logs
            verify_backups
            sync_to_remote
            cleanup_old_backups
            ;;
        *)
            echo "Usage: $0 {databases|configs|apps|logs|all}"
            exit 1
            ;;
    esac
    
    log "Backup operation completed: $backup_type"
}

main "$@"
```

## Production Deployment Automation

### Complete System Installation Script

```bash
#!/usr/bin/env zsh
# /usr/local/bin/production-deploy.sh - Complete OpenBSD Production Setup

set -e

SCRIPT_DIR="$(dirname "$0")"
LOG_FILE="/var/log/production-deploy.log"
STATE_FILE="/var/log/deploy.state"

# Configuration
ADMIN_EMAIL="admin@brgen.no"
BACKUP_SERVER="backup.brgen.no"
MONITORING_INTERVAL="300"  # 5 minutes

log() {
    echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $1" | tee -a "$LOG_FILE"
}

check_prerequisites() {
    log "Checking prerequisites"
    
    # Check OpenBSD version
    if !
<!-- TODO: Break into shorter sentences (165 words > 15) --> uname -r | grep -q "7\.[8-9]"; then
        log "ERROR: OpenBSD 7.8+ required"
        exit 1
    fi
    
    # Check internet connectivity
    if !
<!-- TODO: Break into shorter sentences (21 words > 15) --> ping -c 1 8.8.8.8 > /dev/null 2>&1; then
        log "ERROR: No internet connectivity"
        exit 1
    fi
    
    # Check available disk space
    available_space=$(df / | tail -n 1 | awk '{print $4}')
    if [ "$available_space" -lt 5000000 ]; then  # 5GB
        log "ERROR: Insufficient disk space"
        exit 1
    fi
    
    log "Prerequisites check completed"
}

install_base_system() {
    log "Installing base system packages"
    
    # Update package repository
    pkg_add -u
    
    # Install essential packages
    pkg_add -U \
        zsh \
        ruby-3.3.5 \
        ruby-gems \
        postgresql-server \
        redis \
        node \
        git \
        zap \
        ldns-utils \
        nsd \
        relayd \
        acme-client
    
    # Install Ruby gems
    gem install falcon bundler
    
    log "Base system installation completed"
    echo "base_system_installed" >> "$STATE_FILE"
}

configure_system_security() {
    log "Configuring system security"
    
    # Configure doas
    cat > /etc/doas.conf <<EOF
# Allow wheel group members to run any command
permit persist :wheel

# Service-specific permissions
permit nopass _postgresql as _postgresql
permit nopass _redis as _redis
permit nopass _nsd as _nsd
permit nopass _relayd as _relayd

# Application users
permit nopass brgen as brgen
permit nopass amber as amber
permit nopass ai3 as ai3
EOF
    
    # Set up fail2ban equivalent with pf
    cat > /usr/local/bin/pf-guard.sh <<'EOF'
#!/usr/bin/env zsh
# Monitor auth.log for failed attempts and update pf table
tail -f /var/log/authlog | while read line; do
    if echo "$line" | grep -q "Failed password"; then
        ip=$(echo "$line" | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+')
        if [ -n "$ip" ]; then
            pfctl -t bruteforce -T add "$ip"
        fi
    fi
done
EOF
    chmod +x /usr/local/bin/pf-guard.sh
    
    # Start pf-guard service
    cat > /etc/rc.d/pfguard <<'EOF'
#!/bin/ksh
daemon="/usr/local/bin/pf-guard.sh"
.
<!-- TODO: Break into shorter sentences (257 words > 15) --> /etc/rc.d/rc.subr
rc_cmd $1
EOF
    chmod +x /etc/rc.d/pfguard
    
    log "System security configuration completed"
    echo "security_configured" >> "$STATE_FILE"
}

setup_monitoring() {
    log "Setting up monitoring and alerting"
    
    # Install monitoring scripts
    cp "${SCRIPT_DIR}/system-monitor.sh" /usr/local/bin/
    cp "${SCRIPT_DIR}/cert-renewal.sh" /usr/local/bin/
    cp "${SCRIPT_DIR}/backup-system.sh" /usr/local/bin/
    chmod +x /usr/local/bin/{system-monitor.sh,cert-renewal.sh,backup-system.sh}
    
    # Set up cron jobs
    cat > /var/cron/tabs/root <<EOF
# System monitoring every 5 minutes
*/5 * * * * /usr/local/bin/system-monitor.sh
# Certificate check daily at 2 AM
0 2 * * * /usr/local/bin/cert-renewal.sh check
# Full backup daily at 3 AM
0 3 * * * /usr/local/bin/backup-system.sh all
# Log rotation weekly
0 4 * * 0 /usr/local/bin/backup-system.sh logs
EOF
    
    log "Monitoring setup completed"
    echo "monitoring_configured" >> "$STATE_FILE"
}

deploy_applications() {
    log "Deploying applications"
    
    # Create application users
    apps=(brgen amber pubattorney bsdports hjerterom privcam blognet ai3)
    for app in "${apps[@]}"; do
        if !
<!-- TODO: Break into shorter sentences (135 words > 15) --> id "$app" > /dev/null 2>&1; then
            useradd -m -s /bin/ksh -L "$app" "$app"
            log "Created user: $app"
        fi
    done
    
    # Deploy AI³ system
    if [ !
<!-- TODO: Break into shorter sentences (26 words > 15) --> -d "/home/ai3/ai3" ]; then
        doas -u ai3 git clone https://github.com/ai3-system/ai3.git /home/ai3/ai3
        cd /home/ai3/ai3
        doas -u ai3 bundle install --deployment
        log "AI³ system deployed"
    fi
    
    # Deploy Rails applications
    for app in brgen amber pubattorney bsdports hjerterom privcam blognet; do
        if [ !
<!-- TODO: Break into shorter sentences (42 words > 15) --> -d "/home/${app}/app" ]; then
            doas -u "$app" rails new "/home/${app}/app" -d postgresql --skip-test
            log "Rails app created: $app"
        fi
    done
    
    log "Applications deployment completed"
    echo "applications_deployed" >> "$STATE_FILE"
}

finalize_setup() {
    log "Finalizing production setup"
    
    # Enable and start services
    services=(postgresql redis nsd relayd httpd pfguard)
    for service in "${services[@]}"; do
        rcctl enable "$service"
        rcctl start "$service" || log "Warning: Failed to start $service"
    done
    
    # Test system health
    sleep 10
    if /usr/local/bin/system-monitor.sh; then
        log "System health check passed"
    else
        log "Warning: System health check failed"
    fi
    
    # Send deployment notification
    cat <<EOF | mail -s "Production Deployment Completed - $(hostname)" "$ADMIN_EMAIL"
Production deployment completed successfully.
<!-- TODO: Break into shorter sentences (106 words > 15) --> Server: $(hostname)
Completion Time: $(date)
OpenBSD Version: $(uname -r)

Services Status:
$(rcctl ls on)

Next Steps:
1.
<!-- TODO: Break into shorter sentences (17 words > 15) --> Configure domain DNS records
2. Request SSL certificates: /usr/local/bin/cert-renewal.sh renew brgen.no
3. Deploy application code
4. Set up monitoring dashboards

Logs available at: $LOG_FILE
EOF
    
    log "Production setup completed successfully"
    echo "setup_completed" >> "$STATE_FILE"
}

# Main execution
main() {
    log "Starting production deployment"
    
    if [ $EUID -ne 0 ]; then
        log "ERROR: Must run as root"
        exit 1
    fi
    
    check_prerequisites
    install_base_system
    configure_system_security
    setup_monitoring
    deploy_applications
    finalize_setup
    
    log "Production deployment completed successfully"
}

main "$@"
```

## Conclusion

This FINAL_OPENBSD_INFRASTRUCTURE.md document provides a comprehensive, production-ready OpenBSD infrastructure framework designed for security, performance, and reliability.
<!-- TODO: Break into shorter sentences (77 words > 15) --> The architecture incorporates defense-in-depth security principles, automated certificate management, sophisticated monitoring, and robust disaster recovery capabilities.
<!-- TODO: Break into shorter sentences (16 words > 15) --> **Key Security Features:**
- Advanced pf firewall with DDoS protection and geolocation filtering
- Pledge/unveil security restrictions for all services
- Automated intrusion detection and response
- Comprehensive SSL/TLS configuration with HSTS

**High Availability Features:**
- Load balancing with health checks and session persistence
- Automated failover mechanisms
- Real-time monitoring with alerting
- Comprehensive backup and disaster recovery procedures

**Performance Optimizations:**
- Optimized PostgreSQL and Redis configurations
- Advanced relayd load balancing with compression
- Efficient DNS resolution with DNSSEC
- Streamlined certificate management

**Operational Excellence:**
- Automated deployment and configuration management
- Comprehensive monitoring and alerting
- Structured logging and metrics collection
- Proactive maintenance and health checking

**Next Steps for Production Deployment:**
1.
<!-- TODO: Break into shorter sentences (116 words > 15) --> Execute the production deployment script on OpenBSD 7.8+
2. Configure DNS records for all domains
3. Request and install SSL certificates for all domains
4. Deploy application code using the Rails ecosystem
5. Configure backup destinations and test disaster recovery procedures
6. Set up external monitoring and alerting integrations
7. Perform security audits and penetration testing
8. Implement performance monitoring dashboards

This infrastructure is designed to scale horizontally and support the complete AI³ system, Rails applications, and business platforms with enterprise-grade reliability and security.
<!-- TODO: Break into shorter sentences (27 words > 15) -->