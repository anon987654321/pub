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
all_domains=(
  ["brgen.no"]="markedsplass playlist dating tv takeaway maps"
  ["oshlo.no"]="markedsplass playlist dating tv takeaway maps"
  ["trndheim.no"]="markedsplass playlist dating tv takeaway maps"
  ["stvanger.no"]="markedsplass playlist dating tv takeaway maps"
  ["trmso.no"]="markedsplass playlist dating tv takeaway maps"
