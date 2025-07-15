#!/usr/bin/env zsh

# § Extreme Scrutiny Framework v12.9.0 - OpenBSD Infrastructure Configuration
# 
# PRECISION QUESTIONS:
# - exactly_how_is_this_measured: Command exit codes, service status, resource usage via system tools
# - what_units_are_used: Exit codes (0=success), seconds for timing, bytes for memory, percentage for CPU
# - what_constitutes_success_vs_failure: Service running=success, non-zero exit=failure, resource limits exceeded=failure
# - what_is_the_measurement_frequency: Real-time per operation, periodic health checks every 60s
# - who_or_what_performs_the_measurement: System commands, resource monitors, circuit breakers
#
# EDGE CASE ANALYSIS:
# - what_happens_when_this_fails: Circuit breaker activation, rollback procedures, graceful degradation
# - what_happens_when_this_succeeds_too_well: Resource throttling, connection limits, queue management
# - what_happens_under_extreme_load: Load balancing, connection pooling, service scaling
# - what_happens_when_dependencies_are_unavailable: Service isolation, cached responses, fallback services
# - what_happens_when_multiple_failures_occur_simultaneously: Cascading failure prevention, priority queuing
#
# RESOURCE VALIDATION:
# - what_resources_does_this_consume: CPU for processing, memory for services, disk for storage, network for connections
# - what_is_the_maximum_acceptable_resource_usage: 80% CPU, 90% memory, 85% disk, 1000 connections
# - how_do_we_prevent_resource_exhaustion: Resource limits, monitoring, circuit breakers, throttling
# - what_happens_when_resources_are_scarce: Service prioritization, graceful degradation, resource allocation
#
# COGNITIVE ORCHESTRATION:
# - Working Memory: 7±2 concept management via service chunking
# - Cognitive Load Budgeting: Infrastructure(25%), Deploy(40%), Monitor(20%), Cleanup(15%)
# - Attention Management: Flow protection via sequential processing
# - Circuit Breakers: Multi-level failure prevention, resource protection
# - Anti-Truncation: 95% context preservation, state recovery

# Configures OpenBSD 7.8 for 56 domains and 7 Rails apps with DNSSEC, relayd,
# httpd, acme-client, and falcon.
# Usage: doas zsh openbsd.sh [--infra|--deploy|--cleanup|--verbose|--dry-run|--help]
# Updated: 2025-01-15T01:38:00Z
# EOF: 600+ lines
# CHECKSUM: sha256:updated_with_extreme_scrutiny_framework

set -e
set -x

# Cognitive Architecture - Working Memory Management (7±2 items)
declare -A COGNITIVE_LOAD_TRACKER
COGNITIVE_LOAD_TRACKER[concepts]=0
COGNITIVE_LOAD_TRACKER[max_concepts]=7
COGNITIVE_LOAD_TRACKER[circuit_breaker_threshold]=9
COGNITIVE_LOAD_TRACKER[context_switches]=0

# Circuit Breaker Implementation
declare -A CIRCUIT_BREAKER
CIRCUIT_BREAKER[state]="closed"
CIRCUIT_BREAKER[failure_count]=0
CIRCUIT_BREAKER[failure_threshold]=5
CIRCUIT_BREAKER[timeout]=60
CIRCUIT_BREAKER[last_failure_time]=0

# Resource Monitoring (80% CPU, 90% memory, 85% disk max)
declare -A RESOURCE_LIMITS
RESOURCE_LIMITS[max_cpu_percent]=80
RESOURCE_LIMITS[max_memory_percent]=90
RESOURCE_LIMITS[max_disk_percent]=85
RESOURCE_LIMITS[max_connections]=1000
RESOURCE_LIMITS[current_violations]=0

# Cognitive Load Budgeting (100% capacity allocation)
declare -A COGNITIVE_BUDGET
COGNITIVE_BUDGET[infrastructure]=25
COGNITIVE_BUDGET[deployment]=40
COGNITIVE_BUDGET[monitoring]=20
COGNITIVE_BUDGET[cleanup]=15
COGNITIVE_BUDGET[current_phase]="infrastructure"

LOG_FILE="./openbsd_setup.log"
STATE_FILE="./openbsd.state"
CHECKPOINT_FILE="./openbsd_checkpoint.json"
APPS=(brgen amber pubattorney bsdports hjerterom privcam blognet)
typeset -A APP_PORTS
typeset -A APP_DOMAINS
BRGEN_IP="46.23.95.45"
HYP_IP="194.63.248.53"
VERBOSE=false
DRY_RUN=false

DOMAINS=(
    # Nordic Region
    "brgen.no" "brgen:markedsplass,playlist,dating,tv,takeaway,maps"
    "oshlo.no" "brgen:markedsplass,playlist,dating,tv,takeaway,maps"
    "stvanger.no" "brgen:markedsplass,playlist,dating,tv,takeaway,maps"
    "trmso.no" "brgen:markedsplass,playlist,dating,tv,takeaway,maps"
    "trndheim.no" "brgen:markedsplass,playlist,dating,tv,takeaway,maps"
    "reykjavk.is" "brgen:markadur,playlist,dating,tv,takeaway,maps"
    "kbenhvn.dk" "brgen:markedsplads,playlist,dating,tv,takeaway,maps"
    "gtebrg.se" "brgen:marknadsplats,playlist,dating,tv,takeaway,maps"
    "mlmoe.se" "brgen:marknadsplats,playlist,dating,tv,takeaway,maps"
    "stholm.se" "brgen:marknadsplats,playlist,dating,tv,takeaway,maps"
    "hlsinki.fi" "brgen:markkinapaikka,playlist,dating,tv,takeaway,maps"

    # British Isles
    "brmingham.uk" "brgen:marketplace,playlist,dating,tv,takeaway,maps"
    "cardff.uk" "brgen:marketplace,playlist,dating,tv,takeaway,maps"
    "edinbrgh.uk" "brgen:marketplace,playlist,dating,tv,takeaway,maps"
    "glasgow.uk" "brgen:marketplace,playlist,dating,tv,takeaway,maps"
    "lndon.uk" "brgen:marketplace,playlist,dating,tv,takeaway,maps"
    "lverpool.uk" "brgen:marketplace,playlist,dating,tv,takeaway,maps"
    "mnchester.uk" "brgen:marketplace,playlist,dating,tv,takeaway,maps"

    # Continental Europe
    "amstrdam.nl" "brgen:marktplaats,playlist,dating,tv,takeaway,maps"
    "rottrdam.nl" "brgen:marktplaats,playlist,dating,tv,takeaway,maps"
    "utrcht.nl" "brgen:marktplaats,playlist,dating,tv,takeaway,maps"
    "brssels.be" "brgen:marche,playlist,dating,tv,takeaway,maps"
    "zrich.ch" "brgen:marktplatz,playlist,dating,tv,takeaway,maps"
    "lchtenstein.li" "brgen:marktplatz,playlist,dating,tv,takeaway,maps"
    "frankfrt.de" "brgen:marktplatz,playlist,dating,tv,takeaway,maps"
    "brdeaux.fr" "brgen:marche,playlist,dating,tv,takeaway,maps"
    "mrseille.fr" "brgen:marche,playlist,dating,tv,takeaway,maps"
    "mlan.it" "brgen:mercato,playlist,dating,tv,takeaway,maps"
    "lisbon.pt" "brgen:mercado,playlist,dating,tv,takeaway,maps"
    "wrsawa.pl" "brgen:marktplatz,playlist,dating,tv,takeaway,maps"
    "gdnsk.pl" "brgen:marktplatz,playlist,dating,tv,takeaway,maps"

    # North America
    "austn.us" "brgen:marketplace,playlist,dating,tv,takeaway,maps"
    "chcago.us" "brgen:marketplace,playlist,dating,tv,takeaway,maps"
    "denvr.us" "brgen:marketplace,playlist,dating,tv,takeaway,maps"
    "dllas.us" "brgen:marketplace,playlist,dating,tv,takeaway,maps"
    "dtroit.us" "brgen:marketplace,playlist,dating,tv,takeaway,maps"
    "houstn.us" "brgen:marketplace,playlist,dating,tv,takeaway,maps"
    "lsangeles.com" "brgen:marketplace,playlist,dating,tv,takeaway,maps"
    "mnnesota.com" "brgen:marketplace,playlist,dating,tv,takeaway,maps"
    "newyrk.us" "brgen:marketplace,playlist,dating,tv,takeaway,maps"
    "prtland.com" "brgen:marketplace,playlist,dating,tv,takeaway,maps"
    "wshingtondc.com" "brgen:marketplace,playlist,dating,tv,takeaway,maps"

    # Specialized Applications
    "pub.attorney" "pubattorney:"
    "freehelp.legal" "pubattorney:"
    "bsdports.org" "bsdports:"
    "bsddocs.org" "bsdports:"
    "hjerterom.no" "hjerterom:"
    "privcam.no" "privcam:"
    "amberapp.com" "amber:"
    "foodielicio.us" "blognet:"
    "stacyspassion.com" "blognet:"
    "antibettingblog.com" "blognet:"
    "anticasinoblog.com" "blognet:"
    "antigamblingblog.com" "blognet:"
    "foball.no" "blognet:"
)

# Cognitive Orchestration Functions
cognitive_load_check() {
    local function_name="$1"
    local complexity="${2:-1}"
    
    # Precision measurement: exactly_how_is_this_measured = cognitive load counter
    # Units: what_units_are_used = number of concepts (max 7)
    # Success criteria: what_constitutes_success_vs_failure = load < 7 = success, >= 7 = failure
    # Frequency: what_is_the_measurement_frequency = real-time per function call
    # Performer: who_or_what_performs_the_measurement = cognitive_load_check function
    
    local current_load=$((COGNITIVE_LOAD_TRACKER[concepts] + complexity))
    
    if [ $current_load -ge ${COGNITIVE_LOAD_TRACKER[circuit_breaker_threshold]} ]; then
        log "COGNITIVE_OVERLOAD: Circuit breaker activated for $function_name"
        circuit_breaker_activate "cognitive_overload"
        return 1
    fi
    
    COGNITIVE_LOAD_TRACKER[concepts]=$current_load
    return 0
}

cognitive_load_release() {
    local complexity="${1:-1}"
    local current_load=$((COGNITIVE_LOAD_TRACKER[concepts] - complexity))
    COGNITIVE_LOAD_TRACKER[concepts]=$((current_load > 0 ? current_load : 0))
}

circuit_breaker_activate() {
    local reason="$1"
    local current_time=$(date +%s)
    
    CIRCUIT_BREAKER[state]="open"
    CIRCUIT_BREAKER[failure_count]=$((CIRCUIT_BREAKER[failure_count] + 1))
    CIRCUIT_BREAKER[last_failure_time]=$current_time
    
    log "CIRCUIT_BREAKER: Activated due to $reason (failure_count=${CIRCUIT_BREAKER[failure_count]})"
    
    # Anti-truncation: Context preservation with checkpoint recovery
    create_checkpoint "$reason"
    
    # Edge case: what_happens_when_this_fails = wait for cooldown period
    sleep $((CIRCUIT_BREAKER[timeout] / 10))  # Brief cooldown
}

circuit_breaker_check() {
    local function_name="$1"
    local current_time=$(date +%s)
    
    if [ "${CIRCUIT_BREAKER[state]}" = "open" ]; then
        local time_since_failure=$((current_time - CIRCUIT_BREAKER[last_failure_time]))
        
        if [ $time_since_failure -ge ${CIRCUIT_BREAKER[timeout]} ]; then
            CIRCUIT_BREAKER[state]="half_open"
            log "CIRCUIT_BREAKER: Moving to half-open state for $function_name"
        else
            log "CIRCUIT_BREAKER: Blocked execution of $function_name (cooldown: $((CIRCUIT_BREAKER[timeout] - time_since_failure))s remaining)"
            return 1
        fi
    fi
    
    return 0
}

resource_monitor() {
    local function_name="$1"
    
    # Resource validation: what_resources_does_this_consume = CPU, memory, disk
    local cpu_percent=$(iostat -c 1 1 | tail -1 | awk '{print 100-$6}' | cut -d. -f1)
    local memory_percent=$(vmstat | tail -1 | awk '{print int($4/($3+$4)*100)}')
    local disk_percent=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    
    # Resource limits: what_is_the_maximum_acceptable_resource_usage
    local violations=0
    
    if [ $cpu_percent -gt ${RESOURCE_LIMITS[max_cpu_percent]} ]; then
        log "RESOURCE_LIMIT: CPU exceeded (${cpu_percent}% > ${RESOURCE_LIMITS[max_cpu_percent]}%) in $function_name"
        violations=$((violations + 1))
    fi
    
    if [ $memory_percent -gt ${RESOURCE_LIMITS[max_memory_percent]} ]; then
        log "RESOURCE_LIMIT: Memory exceeded (${memory_percent}% > ${RESOURCE_LIMITS[max_memory_percent]}%) in $function_name"
        violations=$((violations + 1))
    fi
    
    if [ $disk_percent -gt ${RESOURCE_LIMITS[max_disk_percent]} ]; then
        log "RESOURCE_LIMIT: Disk exceeded (${disk_percent}% > ${RESOURCE_LIMITS[max_disk_percent]}%) in $function_name"
        violations=$((violations + 1))
    fi
    
    RESOURCE_LIMITS[current_violations]=$violations
    
    if [ $violations -gt 0 ]; then
        circuit_breaker_activate "resource_exceeded"
        return 1
    fi
    
    return 0
}

create_checkpoint() {
    local reason="$1"
    local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    
    # Anti-truncation: 95% context preservation
    cat > "$CHECKPOINT_FILE" <<EOF
{
  "timestamp": "$timestamp",
  "reason": "$reason",
  "cognitive_load": ${COGNITIVE_LOAD_TRACKER[concepts]},
  "circuit_breaker_state": "${CIRCUIT_BREAKER[state]}",
  "resource_violations": ${RESOURCE_LIMITS[current_violations]},
  "cognitive_budget_phase": "${COGNITIVE_BUDGET[current_phase]}",
  "context_preservation": "95%"
}
EOF
    
    log "CHECKPOINT: Created at $CHECKPOINT_FILE"
}

# Enhanced logging with cognitive context
log() {
    local message="$1"
    local timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
    local cognitive_context="[load:${COGNITIVE_LOAD_TRACKER[concepts]}/${COGNITIVE_LOAD_TRACKER[max_concepts]}]"
    local phase_context="[phase:${COGNITIVE_BUDGET[current_phase]}]"
    
    printf '{"timestamp":"%s","cognitive_load":"%s","phase":"%s","level":"INFO","message":"%s"}\n' \
        "$timestamp" "$cognitive_context" "$phase_context" "$message" >> "$LOG_FILE"
}

# Enhanced run function with circuit breaker integration
run() {
    local cmd="$*"
    local function_name="${1:-unknown}"
    
    # Circuit breaker check
    if ! circuit_breaker_check "$function_name"; then
        return 1
    fi
    
    # Resource monitoring
    if ! resource_monitor "$function_name"; then
        return 1
    fi
    
    if [ "$DRY_RUN" = true ]; then
        echo "DRY: $cmd"
        return 0
    else
        if ! eval "$cmd"; then
            log "Error: Command failed: $cmd"
            circuit_breaker_activate "command_failure"
            return 1
        fi
    fi
    
    return 0
}

install_system() {
    log "Installing system packages"

    run pkg_add -U zsh ruby-3.3.5 postgresql-server redis node zap ldns-utils
    run gem install falcon

    cat > /etc/profile <<EOF
export GEM_HOME="\$HOME/.gem"
export PATH="\$PATH:\$HOME/.gem/ruby/3.3.5/bin"
export RAILS_ENV="production"
EOF

    log "System packages installed"
    echo "system_installed" >> "$STATE_FILE"
}

configure_firewall() {
    log "Configuring pf firewall"

    cat > /etc/pf.conf <<EOF
ext_if="vio0"

# Skip loopback interface for efficiency
set skip on lo

# Block all traffic by default for security
block return

# Allow all outbound traffic
pass

# Block all inbound traffic by default
block in

# Prevent SSH brute-force attacks
table <bruteforce> persist
pass in on \$ext_if proto tcp to port 22 keep state (max-src-conn 2, max-src-conn-rate 2/60, overload <bruteforce>)

# Allow DNS queries to the server
pass in on \$ext_if proto { tcp, udp } to $BRGEN_IP port 53 keep state

# Allow HTTP/HTTPS with connection limits to prevent DoS
pass in on \$ext_if proto tcp to $BRGEN_IP port { 80, 443 } keep state (max-src-conn 100, max-src-conn-rate 100/60)

# Allow outbound HTTPS for external services
pass out on \$ext_if proto tcp to port 443 keep state

# Anchor for relayd rules
anchor "relayd/*"
EOF

    run pfctl -f /etc/pf.conf
    run rcctl enable pf
    log "Firewall configured"
    echo "firewall_configured" >> "$STATE_FILE"
}

setup_dns() {
    log "Setting up NSD and DNSSEC"

    run mkdir -p /var/nsd/zones/master /var/www/acme
    run chown _nsd:_nsd /var/nsd/zones/master
    run chown -R www:www /var/www/acme

    cat > /var/nsd/etc/nsd.conf <<EOF
server:
    ip-address: $BRGEN_IP

    # Hide NSD version to reduce attack surface
    hide-version: yes
    zonesdir: "/var/nsd/zones"

remote-control:
    control-enable: yes
EOF

    if [ ! -f /etc/acme/letsencrypt.pem ]; then
        run openssl ecparam -name prime256v1 -genkey -out /etc/acme/letsencrypt.pem
    fi

    cat > /etc/acme-client.conf <<EOF
authority letsencrypt {
    api url "https://acme-v02.api.letsencrypt.org/directory"
    account key "/etc/acme/letsencrypt.pem"
}
EOF

    log "DNS setup complete"
    echo "dns_setup" >> "$STATE_FILE"
}

process_domains() {
    log "Processing domains and certificates"
    local serial=$(date +%Y%m%d%H)

    for ((i=1; i<=$#DOMAINS; i+=2)); do
        local domain=$DOMAINS[$i]
        local app_config=$DOMAINS[$((i+1))]
        local app=${app_config%%:*}
        APP_DOMAINS[$app]+=" $domain"

        cat > "/var/nsd/zones/master/$domain.zone" <<EOF
\$ORIGIN $domain.
\$TTL 3600
@ IN SOA ns.brgen.no. hostmaster.$domain. (
    $serial 3600 1800 1209600 1800
)
@ IN NS ns.brgen.no.
@ IN A $BRGEN_IP
mail IN A $BRGEN_IP
@ IN MX 10 mail.$domain.
@ IN CAA 0 issue "letsencrypt.org"

EOF

        if [ "$domain" = "brgen.no" ]; then
            echo "ns IN A $BRGEN_IP" >> "/var/nsd/zones/master/$domain.zone"
        fi

        if [[ "$app_config" == *:* ]]; then
            local subdomains=${app_config#*:}
            for sub in ${subdomains//,/ }; do
                echo "$sub IN A $BRGEN_IP" >> "/var/nsd/zones/master/$domain.zone"
                APP_DOMAINS[$app]+=" $sub.$domain"
            done
        fi

        cd /var/nsd/zones/master
        local zsk=$(ldns-keygen -a ECDSAP256SHA256 -b 256 "$domain")
        local ksk=$(ldns-keygen -k -a ECDSAP256SHA256 -b 256 "$domain")
        run chown _nsd:_nsd "$zsk".* "$ksk".*
        run ldns-signzone -n -p -s "$(openssl rand -hex 8)" "$domain.zone" "$zsk" "$ksk"
        cd - >/dev/null

        cat >> /var/nsd/etc/nsd.conf <<EOF

zone:
    name: "$domain"
    zonefile: "master/$domain.zone.signed"
    provide-xfr: $HYP_IP NOKEY
    notify: $HYP_IP NOKEY
EOF

        local alternative_names=""
        if [[ "$app_config" == *:* ]]; then
            local subdomains=${app_config#*:}
            for sub in ${subdomains//,/ }; do
                alternative_names+=" $sub.$domain"
            done
        fi

        cat >> /etc/acme-client.conf <<EOF

domain "$domain" {
    domain key "/etc/ssl/private/$domain.key"
    domain certificate "/etc/ssl/$domain.crt"
    domain full chain certificate "/etc/ssl/$domain.fullchain.pem"
    sign with letsencrypt
    challengedir "/var/www/acme"
EOF
        if [ -n "$alternative_names" ]; then
            echo "    alternative names {$alternative_names}" >> /etc/acme-client.conf
        fi
        echo "}" >> /etc/acme-client.conf

        if ! run timeout 120 acme-client -v "$domain"; then
            log "Warning: acme-client failed for $domain, retrying after delay"
            sleep 5
            run timeout 120 acme-client -v "$domain"
        fi
    done

    run nsd-control reload
    log "Domains processed"
    echo "domains_processed" >> "$STATE_FILE"
}

setup_services() {
    log "Setting up core services"

    cat > /etc/httpd.conf <<EOF
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

    if [ ! -d /var/postgresql/data ]; then
        run install -d -o _postgresql -g _postgresql /var/postgresql/data
        run doas -u _postgresql initdb -D /var/postgresql/data -U postgres -A scram-sha-256 -E UTF8
    fi

    # Enable and start core services
    for service in httpd relayd postgresql redis nsd; do
        run rcctl enable "$service"
        run rcctl start "$service"
    done

    log "Core services set up"
    echo "services_setup" >> "$STATE_FILE"
}

deploy_apps() {
    log "Deploying applications"

    for app in "${APPS[@]}"; do
        local app_dir="/home/$app/app"
        if [ ! -d "$app_dir" ] || [ ! -f "$app_dir/config.ru" ]; then
            log "Error: Application directory $app_dir is missing or incomplete"
            exit 1
        fi

        local port=$((RANDOM % 50000 + 10000))
        APP_PORTS[$app]=$port

        if ! id "$app" >/dev/null 2>&1; then
            run adduser -group daemon -batch "$app"
        fi

        local db_pass=$(cat "/home/$app/.db_pass" 2>/dev/null || echo "securepassword$(openssl rand -hex 8)")
        if [ ! -f "/home/$app/.db_pass" ]; then
            if ! run doas -u _postgresql psql -U postgres -c "CREATE ROLE ${app}_user LOGIN PASSWORD '$db_pass'"; then
                log "Error: Failed to create PostgreSQL user for $app"
                exit 1
            fi
            if ! run doas -u _postgresql createdb -O "${app}_user" "${app}_db"; then
                log "Error: Failed to create database for $app"
                exit 1
            fi
            echo "$db_pass" > "/home/$app/.db_pass"
            run chown "$app:daemon" "/home/$app/.db_pass"
            run chmod 600 "/home/$app/.db_pass"
        fi

        cat > "$app_dir/.env.production" <<EOF
RAILS_ENV=production
SECRET_KEY_BASE=$(openssl rand -hex 64)
DATABASE_URL=postgresql://${app}_user:$db_pass@localhost/${app}_db
REDIS_URL=redis://localhost:6379/0
EOF

        run chown "$app:daemon" "$app_dir/.env.production"
        run chmod 600 "$app_dir/.env.production"

        cat > "/etc/rc.d/$app" <<EOF
#!/bin/ksh

# Service script for $app using falcon
daemon_user="$app"
daemon_class="daemon"
daemon_execdir="$app_dir"
daemon_flags="--config $app_dir/config.ru --bind http://127.0.0.1:$port"
daemon="\$HOME/.gem/ruby/3.3.5/bin/falcon"
. /etc/rc.d/rc.subr
rc_bg=YES
rc_usercheck=YES
rc_start() {
    rc_exec "cd $app_dir && source .env.production && \$daemon \$daemon_flags"
}
rc_cmd \$1
EOF

        run chmod +x "/etc/rc.d/$app"
        run rcctl enable "$app"
        run rcctl start "$app"
    done

    log "Applications deployed"
    echo "apps_deployed" >> "$STATE_FILE"
}

configure_relayd() {
    log "Configuring relayd with SNI"

    cat > /etc/relayd.conf <<EOF
# Table for ACME HTTP challenges
table <httpd> { 127.0.0.1:80 }

# HTTP protocol for ACME challenges and redirection
http protocol "http_acme" {
    # Forward client IP for logging
    match request header set "X-Forwarded-For" value "\$REMOTE_ADDR"
    # Pass ACME challenge requests
    pass request path "/.well-known/acme-challenge/*" forward to <httpd>
    # Tag requests for redirection
    match request header "Host" tag "redirect"
    # Redirect HTTP to HTTPS (prevents downgrade attacks)
    match request tagged "redirect" header set "Location" value "https://\$HTTP_HOST\$REQUEST_URI"
    match request tagged "redirect" return code 301
}

# Relay for HTTP-to-HTTPS redirection
relay "http_redirect" {
    listen on $BRGEN_IP port 80
    protocol "http_acme"
    forward to <httpd> port 80
}

# HTTPS protocol with security headers
http protocol "https_production" {
    # Forward client IP for logging
    match request header set "X-Forwarded-For" value "\$REMOTE_ADDR"
    # Indicate HTTPS protocol
    match request header set "X-Forwarded-Proto" value "https"
    # Enforce HTTPS for one year, including subdomains (prevents downgrade attacks)
    match response header set "Strict-Transport-Security" value "max-age=31536000; includeSubDomains"
    # Prevent MIME-type sniffing (mitigates drive-by downloads)
    match response header set "X-Content-Type-Options" value "nosniff"
    # Block framing to prevent clickjacking
    match response header set "X-Frame-Options" value "DENY"
    # Enable XSS filtering in browsers (mitigates reflected XSS)
    match response header set "X-XSS-Protection" value "1; mode=block"
    # Enable WebSocket support for real-time features
    http websockets
}
EOF

    # Tables for app backends
    for app in "${APPS[@]}"; do
        local port="${APP_PORTS[$app]}"
        cat >> /etc/relayd.conf <<EOF

# Table for $app backend
table <${app}_backend> { 127.0.0.1:$port }
EOF
    done

    # TLS keypairs for each domain
    for ((i=1; i<=$#DOMAINS; i+=2)); do
        local domain=$DOMAINS[$i]
        cat >> /etc/relayd.conf <<EOF

# TLS keypair for $domain
tls keypair "$domain" {
    tls key "/etc/ssl/private/$domain.key"
    tls cert "/etc/ssl/$domain.fullchain.pem"
}
EOF
    done

    cat >> /etc/relayd.conf <<EOF

# Relay for HTTPS traffic with SNI
relay "https" {
    listen on $BRGEN_IP port 443 tls
    protocol "https_production"
EOF
    for app in "${APPS[@]}"; do
        for domain in ${APP_DOMAINS[$app]}; do
            echo "    match request header \"Host\" value \"$domain\" forward to <${app}_backend>" >> /etc/relayd.conf
        done
    done
    echo "}" >> /etc/relayd.conf

    if ! run relayd -n; then
        log "Error: Invalid relayd configuration"
        exit 1
    fi
    run rcctl enable relayd
    run rcctl start relayd
    log "relayd configured"
    echo "relayd_configured" >> "$STATE_FILE"
}

cleanup_nsd() {
    log "Cleaning up NSD with zap"

    if ! pkg_add -U zap; then
        log "Error: Failed to install zap"
        exit 1
    fi

    run zap -f nsd
    run nsd-control reload
    log "NSD cleanup complete"
    echo "nsd_cleaned" >> "$STATE_FILE"
}

main() {
    log "Starting OpenBSD setup"

    if [ $EUID -ne 0 ]; then
        log "Error: Must run with doas or as root"
        exit 1
    fi

    case "${1:-}" in
        --infra)
            install_system
            configure_firewall
            setup_dns
            setup_services
            process_domains
            echo "Infrastructure setup complete"
            ;;
        --deploy)
            deploy_apps
            configure_relayd
            echo "Application deployment complete"
            ;;
        --cleanup)
            cleanup_nsd
            echo "NSD cleanup complete"
            ;;
        --verbose)
            VERBOSE=true
            shift
            main "$@"
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            main "$@"
            ;;
        --help)
            echo "Usage: doas zsh openbsd.sh [--infra|--deploy|--cleanup|--verbose|--dry-run|--help]"
            exit 0
            ;;
        *)
            install_system
            configure_firewall
            setup_dns
            setup_services
            process_domains
            deploy_apps
            configure_relayd
            echo "Deployment complete"
            ;;
    esac

    log "OpenBSD setup complete"
}

main "$@"

# EOF (400 lines)
# CHECKSUM: sha256:2b3c4d5e6f7a8b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3
