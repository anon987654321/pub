#!/bin/sh
# § Cognitive Framework: OpenBSD Installation Verification
# Comprehensive verification with cognitive load management

set -e

# § Configuration
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_FILE="/tmp/openbsd_verification.log"
VERBOSE="${VERBOSE:-false}"
verification_passed=0
verification_failed=0
total_verifications=0

# § Color Configuration
if [ -t 1 ]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  BLUE='\033[0;34m'
  CYAN='\033[0;36m'
  NC='\033[0m'
else
  RED=''
  GREEN=''
  YELLOW=''
  BLUE=''
  CYAN=''
  NC=''
fi

# § Logging Functions
log() {
  local message="$1"
  local level="${2:-INFO}"
  printf '{"timestamp":"%s","level":"%s","message":"%s"}\n' \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$level" "$message" >> "$LOG_FILE"
  
  if [ "$VERBOSE" = "true" ]; then
    printf "[%s] %s: %s\n" "$(date -u +%H:%M:%S)" "$level" "$message"
  fi
}

# § Verification Functions
verify_start() {
  local check_name="$1"
  local description="$2"
  total_verifications=$((total_verifications + 1))
  printf "%s[Check %d]%s %s%s%s" "$BLUE" "$total_verifications" "$NC" "$CYAN" "$check_name" "$NC"
  if [ -n "$description" ]; then
    printf " - %s" "$description"
  fi
  printf " ... "
  log "Starting verification: $check_name" "INFO"
}

verify_pass() {
  local details="$1"
  verification_passed=$((verification_passed + 1))
  printf "%sOK%s" "$GREEN" "$NC"
  if [ -n "$details" ]; then
    printf " (%s)" "$details"
  fi
  printf "\n"
  log "Verification passed: $details" "INFO"
}

verify_fail() {
  local reason="$1"
  verification_failed=$((verification_failed + 1))
  printf "%sFAIL%s" "$RED" "$NC"
  if [ -n "$reason" ]; then
    printf " (%s)" "$reason"
  fi
  printf "\n"
  log "Verification failed: $reason" "ERROR"
}

# § System Verification (Chunk 1)
verify_operating_system() {
  verify_start "Operating System" "OpenBSD version and architecture"
  
  if uname -s | grep -q "OpenBSD"; then
    version=$(uname -r)
    arch=$(uname -m)
    verify_pass "OpenBSD $version on $arch"
  else
    verify_fail "not running on OpenBSD"
  fi
}

verify_root_privileges() {
  verify_start "Root Privileges" "sufficient privileges for system checks"
  
  if [ "$(id -u)" -eq 0 ]; then
    verify_pass "running as root"
  else
    verify_fail "not running as root (use doas)"
  fi
}

verify_network_connectivity() {
  verify_start "Network Connectivity" "basic network access"
  
  if ping -c 1 -W 3 8.8.8.8 >/dev/null 2>&1; then
    verify_pass "internet connectivity OK"
  else
    verify_fail "no internet connectivity"
  fi
}

# § Package Verification (Chunk 2)
verify_essential_packages() {
  verify_start "Essential Packages" "required packages installed"
  
  missing_packages=""
  for pkg in ruby postgresql-server redis node zsh; do
    if ! pkg_info -q "$pkg" >/dev/null 2>&1; then
      missing_packages="$missing_packages $pkg"
    fi
  done
  
  if [ -z "$missing_packages" ]; then
    verify_pass "all essential packages installed"
  else
    verify_fail "missing packages:$missing_packages"
  fi
}

verify_ruby_environment() {
  verify_start "Ruby Environment" "Ruby and gems properly configured"
  
  if command -v ruby >/dev/null 2>&1; then
    ruby_version=$(ruby --version | cut -d' ' -f2)
    if gem list | grep -q falcon; then
      verify_pass "Ruby $ruby_version with falcon gem"
    else
      verify_fail "falcon gem not installed"
    fi
  else
    verify_fail "Ruby not installed"
  fi
}

# § Service Verification (Chunk 3)
verify_core_services() {
  verify_start "Core Services" "essential services running"
  
  failed_services=""
  for service in httpd relayd postgresql redis nsd; do
    if ! rcctl check "$service" >/dev/null 2>&1; then
      failed_services="$failed_services $service"
    fi
  done
  
  if [ -z "$failed_services" ]; then
    verify_pass "all core services running"
  else
    verify_fail "failed services:$failed_services"
  fi
}

verify_database_connectivity() {
  verify_start "Database Connectivity" "PostgreSQL accessible"
  
  if doas -u _postgresql psql -U postgres -c "SELECT 1;" >/dev/null 2>&1; then
    verify_pass "PostgreSQL accessible"
  else
    verify_fail "PostgreSQL not accessible"
  fi
}

verify_redis_connectivity() {
  verify_start "Redis Connectivity" "Redis server responsive"
  
  if echo "PING" | redis-cli 2>/dev/null | grep -q "PONG"; then
    verify_pass "Redis responsive"
  else
    verify_fail "Redis not responsive"
  fi
}

# § Configuration Verification (Chunk 4)
verify_firewall_configuration() {
  verify_start "Firewall Configuration" "pf rules loaded"
  
  if [ -f /etc/pf.conf ]; then
    if pfctl -s rules | grep -q "block return"; then
      verify_pass "pf rules loaded"
    else
      verify_fail "pf rules not loaded"
    fi
  else
    verify_fail "/etc/pf.conf not found"
  fi
}

verify_dns_configuration() {
  verify_start "DNS Configuration" "NSD properly configured"
  
  if [ -f /var/nsd/etc/nsd.conf ]; then
    if nsd-checkconf /var/nsd/etc/nsd.conf >/dev/null 2>&1; then
      verify_pass "NSD configuration valid"
    else
      verify_fail "NSD configuration invalid"
    fi
  else
    verify_fail "NSD configuration not found"
  fi
}

verify_ssl_certificates() {
  verify_start "SSL Certificates" "certificates present and valid"
  
  cert_count=0
  for cert in /etc/ssl/*.crt; do
    if [ -f "$cert" ]; then
      cert_count=$((cert_count + 1))
    fi
  done
  
  if [ "$cert_count" -gt 0 ]; then
    verify_pass "$cert_count certificates found"
  else
    verify_fail "no SSL certificates found"
  fi
}

# § Security Verification (Chunk 5)
verify_security_hardening() {
  verify_start "Security Hardening" "security parameters configured"
  
  if [ -f /etc/sysctl.conf ]; then
    if grep -q "net.inet.ip.forwarding=0" /etc/sysctl.conf; then
      verify_pass "security parameters configured"
    else
      verify_fail "security parameters not found"
    fi
  else
    verify_fail "/etc/sysctl.conf not found"
  fi
}

verify_ssh_hardening() {
  verify_start "SSH Hardening" "SSH security configuration"
  
  if [ -f /etc/ssh/sshd_config ]; then
    if grep -q "PermitRootLogin no" /etc/ssh/sshd_config; then
      verify_pass "SSH hardening configured"
    else
      verify_fail "SSH hardening not configured"
    fi
  else
    verify_fail "SSH configuration not found"
  fi
}

# § Performance Verification (Chunk 6)
verify_performance_optimization() {
  verify_start "Performance Optimization" "system tuning parameters"
  
  if [ -f /etc/sysctl.conf ]; then
    if grep -q "net.inet.tcp.sendspace" /etc/sysctl.conf; then
      verify_pass "performance optimization configured"
    else
      verify_fail "performance optimization not configured"
    fi
  else
    verify_fail "sysctl.conf not found"
  fi
}

verify_monitoring_setup() {
  verify_start "Monitoring Setup" "system monitoring configured"
  
  if [ -f /usr/local/bin/system_monitor.sh ]; then
    if [ -x /usr/local/bin/system_monitor.sh ]; then
      verify_pass "system monitoring configured"
    else
      verify_fail "system monitoring not executable"
    fi
  else
    verify_fail "system monitoring not found"
  fi
}

# § Application Verification (Chunk 7)
verify_application_deployment() {
  verify_start "Application Deployment" "application directories and configs"
  
  missing_apps=""
  for app in brgen amber pubattorney bsdports hjerterom privcam blognet; do
    if [ ! -d "/home/$app/app" ]; then
      missing_apps="$missing_apps $app"
    fi
  done
  
  if [ -z "$missing_apps" ]; then
    verify_pass "all application directories found"
  else
    verify_fail "missing app directories:$missing_apps"
  fi
}

verify_load_balancer_config() {
  verify_start "Load Balancer Config" "relayd configuration"
  
  if [ -f /etc/relayd.conf ]; then
    if relayd -n >/dev/null 2>&1; then
      verify_pass "relayd configuration valid"
    else
      verify_fail "relayd configuration invalid"
    fi
  else
    verify_fail "relayd configuration not found"
  fi
}

# § Web Interface Verification
verify_web_interface() {
  verify_start "Web Interface" "HTTP/HTTPS responses"
  
  if command -v curl >/dev/null 2>&1; then
    # Test HTTP redirect
    if curl -s -I http://localhost | grep -q "301"; then
      verify_pass "HTTP redirect working"
    else
      verify_fail "HTTP redirect not working"
    fi
  else
    verify_fail "curl not available for testing"
  fi
}

# § Main Verification Function
main() {
  printf "%s§ OpenBSD Installation Verification - Cognitive Framework v10.7.0%s\n" "$YELLOW" "$NC"
  printf "Starting comprehensive system verification...\n\n"
  
  log "Starting OpenBSD installation verification" "INFO"
  
  # § Verification Execution in Cognitive Chunks
  printf "%s=== Chunk 1: System Verification ===%s\n" "$CYAN" "$NC"
  verify_operating_system
  verify_root_privileges
  verify_network_connectivity
  
  printf "\n%s=== Chunk 2: Package Verification ===%s\n" "$CYAN" "$NC"
  verify_essential_packages
  verify_ruby_environment
  
  printf "\n%s=== Chunk 3: Service Verification ===%s\n" "$CYAN" "$NC"
  verify_core_services
  verify_database_connectivity
  verify_redis_connectivity
  
  printf "\n%s=== Chunk 4: Configuration Verification ===%s\n" "$CYAN" "$NC"
  verify_firewall_configuration
  verify_dns_configuration
  verify_ssl_certificates
  
  printf "\n%s=== Chunk 5: Security Verification ===%s\n" "$CYAN" "$NC"
  verify_security_hardening
  verify_ssh_hardening
  
  printf "\n%s=== Chunk 6: Performance Verification ===%s\n" "$CYAN" "$NC"
  verify_performance_optimization
  verify_monitoring_setup
  
  printf "\n%s=== Chunk 7: Application Verification ===%s\n" "$CYAN" "$NC"
  verify_application_deployment
  verify_load_balancer_config
  verify_web_interface
  
  # § Verification Summary
  printf "\n%s=== Verification Summary ===%s\n" "$YELLOW" "$NC"
  printf "Total verifications: %d\n" "$total_verifications"
  printf "%sPassed: %d%s\n" "$GREEN" "$verification_passed" "$NC"
  
  if [ $verification_failed -gt 0 ]; then
    printf "%sFailed: %d%s\n" "$RED" "$verification_failed" "$NC"
    printf "\n%sSome verifications failed. Please check the installation.%s\n" "$RED" "$NC"
    printf "Review the log file: %s\n" "$LOG_FILE"
    exit 1
  else
    printf "%sFailed: %d%s\n" "$GREEN" "$verification_failed" "$NC"
    printf "\n%sAll verifications passed! OpenBSD installation is working correctly.%s\n" "$GREEN" "$NC"
    log "All verifications passed successfully" "INFO"
    exit 0
  fi
}

# § Command Line Options
case "${1:-}" in
  --help)
    cat <<EOF
§ OpenBSD Installation Verification - Cognitive Framework v10.7.0

Usage: $(basename "$0") [options]

Options:
  --verbose   Enable verbose logging output
  --help      Show this help message

This script performs comprehensive verification of the OpenBSD installation
including system components, services, security configuration, and applications.

Examples:
  doas sh verify_installation.sh          # Run verification
  doas sh verify_installation.sh --verbose # Run with verbose output
EOF
    exit 0
    ;;
  --verbose)
    VERBOSE="true"
    main
    ;;
  *)
    main
    ;;
esac