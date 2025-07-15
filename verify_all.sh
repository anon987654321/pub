#!/bin/bash

# Comprehensive verification script for OpenBSD 7.8 infrastructure and Rails applications
# Checks status and health of all Rails applications and OpenBSD infrastructure
# Usage: ./verify_all.sh [--verbose|--quiet|--json|--help]
# Created: 2025-01-21

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_FILE="/tmp/verify_all_$(date +%Y%m%d_%H%M%S).log"
REPORT_FILE="/tmp/verify_report_$(date +%Y%m%d_%H%M%S).txt"
VERBOSE=false
QUIET=false
JSON_OUTPUT=false

# Infrastructure configuration from openbsd.sh
APPS=(brgen amber pubattorney bsdports hjerterom privcam blognet)
BRGEN_IP="46.23.95.45"
HYP_IP="194.63.248.53"
BASE_DIR="/home/dev/rails"
RAILS_VERSION="8.0.0"
RUBY_VERSION="3.3.0"
NODE_VERSION="20"

# Domain list (extracted from openbsd.sh)
DOMAINS=(
    # Nordic Region
    "brgen.no" "oshlo.no" "stvanger.no" "trmso.no" "trndheim.no"
    "reykjavk.is" "kbenhvn.dk" "gtebrg.se" "mlmoe.se" "stholm.se" "hlsinki.fi"
    # British Isles
    "brmingham.uk" "cardff.uk" "edinbrgh.uk" "glasgow.uk" "lndon.uk" "lverpool.uk" "mnchester.uk"
    # Continental Europe
    "amstrdam.nl" "rottrdam.nl" "utrcht.nl" "brssels.be" "zrich.ch" "lchtenstein.li"
    "frankfrt.de" "brdeaux.fr" "mrseille.fr" "mlan.it" "lisbon.pt" "wrsawa.pl" "gdnsk.pl"
    # North America
    "austn.us" "chcago.us" "denvr.us" "dllas.us" "dtroit.us" "houstn.us"
    "lsangeles.com" "mnnesota.com" "newyrk.us" "prtland.com" "wshingtondc.com"
    # Specialized Applications
    "pub.attorney" "freehelp.legal" "bsdports.org" "bsddocs.org" "hjerterom.no"
    "privcam.no" "amberapp.com" "foodielicio.us" "stacyspassion.com"
    "antibettingblog.com" "anticasinoblog.com" "antigamblingblog.com" "foball.no"
)

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Status counters
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0
WARNING_CHECKS=0

# Usage function
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Comprehensive verification script for OpenBSD 7.8 infrastructure and Rails applications

OPTIONS:
    --verbose   Show detailed output for all checks
    --quiet     Only show errors and warnings
    --json      Output results in JSON format
    --help      Show this help message

EXAMPLES:
    $0                  # Run all checks with standard output
    $0 --verbose        # Run with detailed output
    $0 --json > report.json  # Generate JSON report

EOF
}

# Logging functions
log() {
    local level="$1"
    shift
    local message="$*"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
    
    if [ "$JSON_OUTPUT" = true ]; then
        return
    fi
    
    case "$level" in
        "INFO")
            [ "$QUIET" = false ] && echo -e "${BLUE}[INFO]${NC} $message"
            ;;
        "PASS")
            [ "$QUIET" = false ] && echo -e "${GREEN}[PASS]${NC} $message"
            ;;
        "WARN")
            echo -e "${YELLOW}[WARN]${NC} $message"
            ;;
        "FAIL")
            echo -e "${RED}[FAIL]${NC} $message"
            ;;
        "ERROR")
            echo -e "${RED}[ERROR]${NC} $message"
            ;;
    esac
}

# Check result tracking
check_result() {
    local status="$1"
    local message="$2"
    local suggestion="${3:-}"
    
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    case "$status" in
        "PASS")
            PASSED_CHECKS=$((PASSED_CHECKS + 1))
            log "PASS" "$message"
            ;;
        "FAIL")
            FAILED_CHECKS=$((FAILED_CHECKS + 1))
            log "FAIL" "$message"
            [ -n "$suggestion" ] && log "INFO" "Suggestion: $suggestion"
            ;;
        "WARN")
            WARNING_CHECKS=$((WARNING_CHECKS + 1))
            log "WARN" "$message"
            [ -n "$suggestion" ] && log "INFO" "Suggestion: $suggestion"
            ;;
    esac
}

# System health checks
check_openbsd_services() {
    log "INFO" "Checking OpenBSD system services..."
    
    # Check PostgreSQL
    if pgrep -x postgres > /dev/null; then
        check_result "PASS" "PostgreSQL service is running"
    else
        check_result "FAIL" "PostgreSQL service is not running" "Start with: rcctl start postgresql"
    fi
    
    # Check Redis
    if pgrep -x redis-server > /dev/null; then
        check_result "PASS" "Redis service is running"
    else
        check_result "FAIL" "Redis service is not running" "Start with: rcctl start redis"
    fi
    
    # Check httpd
    if pgrep -x httpd > /dev/null; then
        check_result "PASS" "httpd service is running"
    else
        check_result "FAIL" "httpd service is not running" "Start with: rcctl start httpd"
    fi
    
    # Check relayd
    if pgrep -x relayd > /dev/null; then
        check_result "PASS" "relayd service is running"
    else
        check_result "FAIL" "relayd service is not running" "Start with: rcctl start relayd"
    fi
    
    # Check pf firewall
    if command -v pfctl > /dev/null 2>&1; then
        if pfctl -sr > /dev/null 2>&1; then
            check_result "PASS" "pf firewall is active"
        else
            check_result "FAIL" "pf firewall is not active" "Enable with: pfctl -e"
        fi
    else
        check_result "WARN" "pf firewall not available (not OpenBSD system)" "Run on OpenBSD system"
    fi
}

# SSL certificate verification
check_ssl_certificates() {
    log "INFO" "Checking SSL certificates..."
    
    local cert_dir="/etc/ssl/acme"
    local checked_count=0
    local max_checks=10  # Limit to first 10 domains to avoid timeout
    
    for domain in "${DOMAINS[@]}"; do
        if [ $checked_count -ge $max_checks ]; then
            log "INFO" "Checked $max_checks domains, skipping remaining for performance"
            break
        fi
        
        local cert_file="$cert_dir/$domain.crt"
        if [ -f "$cert_file" ]; then
            local expiry=$(openssl x509 -in "$cert_file" -noout -enddate 2>/dev/null | cut -d= -f2)
            if [ -n "$expiry" ]; then
                local expiry_epoch=$(date -d "$expiry" +%s 2>/dev/null || echo "0")
                local now_epoch=$(date +%s)
                local days_until_expiry=$(((expiry_epoch - now_epoch) / 86400))
                
                if [ $days_until_expiry -gt 30 ]; then
                    check_result "PASS" "SSL certificate for $domain valid for $days_until_expiry days"
                elif [ $days_until_expiry -gt 7 ]; then
                    check_result "WARN" "SSL certificate for $domain expires in $days_until_expiry days" "Renew certificate soon"
                else
                    check_result "FAIL" "SSL certificate for $domain expires in $days_until_expiry days" "Renew certificate immediately"
                fi
            else
                check_result "FAIL" "Cannot read SSL certificate for $domain" "Check certificate file: $cert_file"
            fi
        else
            check_result "FAIL" "SSL certificate not found for $domain" "Generate certificate with acme-client"
        fi
        
        checked_count=$((checked_count + 1))
    done
}

# DNS resolution checks
check_dns_resolution() {
    log "INFO" "Checking DNS resolution..."
    
    local checked_count=0
    local max_checks=10  # Limit to first 10 domains
    
    for domain in "${DOMAINS[@]}"; do
        if [ $checked_count -ge $max_checks ]; then
            log "INFO" "Checked $max_checks domains, skipping remaining for performance"
            break
        fi
        
        if nslookup "$domain" > /dev/null 2>&1; then
            check_result "PASS" "DNS resolution successful for $domain"
        else
            check_result "FAIL" "DNS resolution failed for $domain" "Check DNS configuration"
        fi
        
        checked_count=$((checked_count + 1))
    done
}

# Rails application checks
check_rails_applications() {
    log "INFO" "Checking Rails applications..."
    
    for app in "${APPS[@]}"; do
        local app_dir="$BASE_DIR/$app"
        
        # Check application directory
        if [ -d "$app_dir" ]; then
            check_result "PASS" "Application directory exists for $app"
        else
            check_result "FAIL" "Application directory missing for $app" "Create directory: mkdir -p $app_dir"
            continue
        fi
        
        # Check Gemfile
        if [ -f "$app_dir/Gemfile" ]; then
            check_result "PASS" "Gemfile exists for $app"
        else
            check_result "FAIL" "Gemfile missing for $app" "Initialize Rails app or create Gemfile"
        fi
        
        # Check package.json
        if [ -f "$app_dir/package.json" ]; then
            check_result "PASS" "package.json exists for $app"
        else
            check_result "WARN" "package.json missing for $app" "Run: npm init if needed"
        fi
        
        # Check database connectivity
        if [ -f "$app_dir/config/database.yml" ]; then
            check_result "PASS" "Database configuration exists for $app"
        else
            check_result "FAIL" "Database configuration missing for $app" "Create config/database.yml"
        fi
        
        # Check if Falcon server is running
        if pgrep -f "falcon.*$app" > /dev/null; then
            check_result "PASS" "Falcon server running for $app"
        else
            check_result "FAIL" "Falcon server not running for $app" "Start with: rcctl start $app"
        fi
        
        # Check environment file
        if [ -f "$app_dir/.env.production" ]; then
            check_result "PASS" "Environment file exists for $app"
        else
            check_result "WARN" "Environment file missing for $app" "Create .env.production with required variables"
        fi
    done
}

# Infrastructure verification
check_infrastructure() {
    log "INFO" "Checking infrastructure components..."
    
    # Check shared utilities
    if [ -f "$SCRIPT_DIR/rails/__shared.sh" ]; then
        check_result "PASS" "Shared utilities script exists"
    else
        check_result "FAIL" "Shared utilities script missing" "Ensure rails/__shared.sh exists"
    fi
    
    # Check OpenBSD setup script
    if [ -f "$SCRIPT_DIR/openbsd/openbsd.sh" ]; then
        check_result "PASS" "OpenBSD setup script exists"
    else
        check_result "FAIL" "OpenBSD setup script missing" "Ensure openbsd/openbsd.sh exists"
    fi
    
    # Check log directory
    if [ -d "/var/log" ]; then
        check_result "PASS" "System log directory accessible"
    else
        check_result "FAIL" "System log directory not accessible" "Check permissions"
    fi
    
    # Check disk space
    local disk_usage=$(df -h / | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ "$disk_usage" -lt 80 ]; then
        check_result "PASS" "Disk usage is acceptable ($disk_usage%)"
    elif [ "$disk_usage" -lt 90 ]; then
        check_result "WARN" "Disk usage is high ($disk_usage%)" "Consider cleaning up disk space"
    else
        check_result "FAIL" "Disk usage is critical ($disk_usage%)" "Free up disk space immediately"
    fi
    
    # Check memory usage (OpenBSD compatible)
    if command -v free > /dev/null 2>&1; then
        local mem_usage=$(free | grep Mem | awk '{print ($3/$2) * 100.0}' | cut -d. -f1 2>/dev/null || echo "50")
        if [ "$mem_usage" -lt 80 ]; then
            check_result "PASS" "Memory usage is acceptable ($mem_usage%)"
        elif [ "$mem_usage" -lt 90 ]; then
            check_result "WARN" "Memory usage is high ($mem_usage%)" "Monitor memory usage"
        else
            check_result "FAIL" "Memory usage is critical ($mem_usage%)" "Investigate memory leaks"
        fi
    else
        check_result "WARN" "Cannot check memory usage (free command not available)" "Check memory manually"
    fi
}

# Feature-specific checks
check_features() {
    log "INFO" "Checking feature-specific components..."
    
    # Check if Ruby version is correct
    if command -v ruby > /dev/null 2>&1; then
        local ruby_version=$(ruby -v | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1)
        if [ "$ruby_version" = "$RUBY_VERSION" ]; then
            check_result "PASS" "Ruby version is correct ($ruby_version)"
        else
            check_result "WARN" "Ruby version mismatch (expected $RUBY_VERSION, got $ruby_version)" "Update Ruby version"
        fi
    else
        check_result "FAIL" "Ruby not found" "Install Ruby $RUBY_VERSION"
    fi
    
    # Check if Node.js version is correct
    if command -v node > /dev/null 2>&1; then
        local node_version=$(node -v | grep -o '[0-9]\+' | head -1)
        if [ "$node_version" = "$NODE_VERSION" ]; then
            check_result "PASS" "Node.js version is correct ($node_version)"
        else
            check_result "WARN" "Node.js version mismatch (expected $NODE_VERSION, got $node_version)" "Update Node.js version"
        fi
    else
        check_result "FAIL" "Node.js not found" "Install Node.js $NODE_VERSION"
    fi
    
    # Check for Falcon gem
    if gem list falcon | grep -q falcon; then
        check_result "PASS" "Falcon gem is installed"
    else
        check_result "FAIL" "Falcon gem not installed" "Install with: gem install falcon"
    fi
    
    # Check for critical directories
    local critical_dirs=("/tmp" "/var/tmp" "/home/dev")
    for dir in "${critical_dirs[@]}"; do
        if [ -d "$dir" ] && [ -w "$dir" ]; then
            check_result "PASS" "Critical directory $dir is accessible and writable"
        else
            check_result "FAIL" "Critical directory $dir is not accessible or writable" "Check permissions on $dir"
        fi
    done
}

# Network and security checks
check_network_security() {
    log "INFO" "Checking network and security configuration..."
    
    # Check if required ports are open
    local required_ports=(22 53 80 443)
    for port in "${required_ports[@]}"; do
        if netstat -ln | grep -q ":$port "; then
            check_result "PASS" "Port $port is listening"
        else
            check_result "FAIL" "Port $port is not listening" "Check service configuration for port $port"
        fi
    done
    
    # Check firewall rules
    if command -v pfctl > /dev/null 2>&1; then
        if pfctl -sr 2>/dev/null | grep -q "pass in"; then
            check_result "PASS" "Firewall rules are configured"
        else
            check_result "WARN" "No firewall rules found" "Configure pf rules in /etc/pf.conf"
        fi
    else
        check_result "WARN" "pfctl command not available (not OpenBSD system)" "Run on OpenBSD system"
    fi
    
    # Check for SSH brute force protection
    if command -v pfctl > /dev/null 2>&1; then
        if pfctl -sr 2>/dev/null | grep -q bruteforce; then
            check_result "PASS" "SSH brute force protection is enabled"
        else
            check_result "WARN" "SSH brute force protection not configured" "Add bruteforce table to pf.conf"
        fi
    else
        check_result "WARN" "Cannot check SSH brute force protection (pfctl not available)" "Run on OpenBSD system"
    fi
}

# HTTP response checks
check_http_responses() {
    log "INFO" "Checking HTTP responses (limited sample)..."
    
    local test_domains=("localhost" "127.0.0.1")
    
    for domain in "${test_domains[@]}"; do
        # Test HTTP response
        if curl -s -o /dev/null -w "%{http_code}" "http://$domain" | grep -q "200\|301\|302"; then
            check_result "PASS" "HTTP response from $domain is valid"
        else
            check_result "FAIL" "HTTP response from $domain is invalid" "Check web server configuration"
        fi
    done
}

# Generate summary report
generate_report() {
    local report_content=""
    
    if [ "$JSON_OUTPUT" = true ]; then
        cat << EOF
{
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "summary": {
    "total_checks": $TOTAL_CHECKS,
    "passed": $PASSED_CHECKS,
    "failed": $FAILED_CHECKS,
    "warnings": $WARNING_CHECKS,
    "success_rate": "$(if command -v bc > /dev/null 2>&1 && [ $TOTAL_CHECKS -gt 0 ]; then echo "scale=2; $PASSED_CHECKS * 100 / $TOTAL_CHECKS" | bc -l 2>/dev/null || echo "0"; else echo "0"; fi)%"
  },
  "status": "$([ $FAILED_CHECKS -eq 0 ] && echo "HEALTHY" || echo "ISSUES_FOUND")",
  "log_file": "$LOG_FILE"
}
EOF
    else
        echo
        echo "================================================="
        echo "           VERIFICATION SUMMARY REPORT"
        echo "================================================="
        echo "Timestamp: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
        echo
        echo "Total Checks: $TOTAL_CHECKS"
        echo -e "Passed: ${GREEN}$PASSED_CHECKS${NC}"
        echo -e "Failed: ${RED}$FAILED_CHECKS${NC}"
        echo -e "Warnings: ${YELLOW}$WARNING_CHECKS${NC}"
        echo
        local success_rate="N/A"
        if command -v bc > /dev/null 2>&1 && [ $TOTAL_CHECKS -gt 0 ]; then
            success_rate=$(echo "scale=2; $PASSED_CHECKS * 100 / $TOTAL_CHECKS" | bc -l 2>/dev/null || echo "N/A")
        fi
        echo "Success Rate: $success_rate%"
        echo
        if [ $FAILED_CHECKS -eq 0 ]; then
            echo -e "Overall Status: ${GREEN}HEALTHY${NC}"
        else
            echo -e "Overall Status: ${RED}ISSUES FOUND${NC}"
        fi
        echo
        echo "Detailed log: $LOG_FILE"
        echo "================================================="
    fi
}

# Main execution
main() {
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --verbose)
                VERBOSE=true
                shift
                ;;
            --quiet)
                QUIET=true
                shift
                ;;
            --json)
                JSON_OUTPUT=true
                QUIET=true
                shift
                ;;
            --help)
                usage
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done
    
    # Initialize log file
    echo "Verification started at $(date -u +"%Y-%m-%dT%H:%M:%SZ")" > "$LOG_FILE"
    
    if [ "$JSON_OUTPUT" = false ]; then
        echo "================================================="
        echo "    OpenBSD Infrastructure Verification Script"
        echo "================================================="
        echo "Starting comprehensive system verification..."
        echo
    fi
    
    # Run all checks
    check_openbsd_services
    check_ssl_certificates
    check_dns_resolution
    check_rails_applications
    check_infrastructure
    check_features
    check_network_security
    check_http_responses
    
    # Generate final report
    generate_report
    
    # Exit with appropriate code
    if [ $FAILED_CHECKS -eq 0 ]; then
        exit 0
    else
        exit 1
    fi
}

# Run main function
main "$@"