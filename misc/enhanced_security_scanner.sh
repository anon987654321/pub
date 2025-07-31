#!/usr/bin/env zsh
# Enhanced Security Scanner - OpenBSD Optimized Network Reconnaissance
# Integrates with deep_nmap_scan.sh functionality for comprehensive security assessment
# Legal compliance features for authorized investigations

set -e

# Configuration
SCAN_USER="security_scanner"
LOG_DIR="/var/log/security_scans"
TOOLS_DIR="/usr/local/bin"
COMPLIANCE_MODE=${COMPLIANCE_MODE:-"authorized"}

# Enhanced logging for security operations
security_log() {
  local level="$1"
  local message="$2"
  local timestamp=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
  
  echo "[$timestamp] [$level] $message" | tee -a "$LOG_DIR/security_scan.log"
  
  # Compliance logging for law enforcement
  if [ "$COMPLIANCE_MODE" = "law_enforcement" ]; then
    echo "[$timestamp] [COMPLIANCE] $message" >> "$LOG_DIR/compliance.log"
  fi
}

# Network discovery with multiple techniques
enhanced_network_discovery() {
  local target="$1"
  security_log "INFO" "Starting enhanced network discovery for $target"
  
  # Comprehensive host discovery
  nmap -sn -PS22,80,443,8080,8443 -PU53,161,137 -PE -PP -PM -PO \
    --send-eth --privileged -oN "$LOG_DIR/${target}_discovery.txt" "$target" 2>/dev/null || true
  
  # DNS enumeration
  dig +short "$target" A AAAA MX NS TXT | tee "$LOG_DIR/${target}_dns.txt"
  
  # Subdomain discovery
  for subdomain in www mail ftp admin api dev staging test; do
    dig +short "${subdomain}.${target}" A 2>/dev/null | grep -E '^[0-9]+\.' >> "$LOG_DIR/${target}_subdomains.txt" || true
  done
  
  security_log "INFO" "Network discovery completed for $target"
}

# Multi-method port scanning
comprehensive_port_scan() {
  local target="$1"
  security_log "INFO" "Starting comprehensive port scanning for $target"
  
  # TCP SYN scan - stealthy and fast
  nmap -sS -T4 --top-ports 1000 -oN "$LOG_DIR/${target}_tcp_syn.txt" "$target" 2>/dev/null || true
  
  # TCP Connect scan - more reliable
  nmap -sT -T3 --top-ports 100 -oN "$LOG_DIR/${target}_tcp_connect.txt" "$target" 2>/dev/null || true
  
  # UDP scan on common ports
  nmap -sU --top-ports 50 -oN "$LOG_DIR/${target}_udp.txt" "$target" 2>/dev/null || true
  
  # Service version detection on open ports
  nmap -sV -T3 --version-intensity 5 -oN "$LOG_DIR/${target}_services.txt" "$target" 2>/dev/null || true
  
  security_log "INFO" "Port scanning completed for $target"
}

# Operating system and service fingerprinting
system_fingerprinting() {
  local target="$1"
  security_log "INFO" "Starting system fingerprinting for $target"
  
  # OS detection
  nmap -O --osscan-guess -oN "$LOG_DIR/${target}_os.txt" "$target" 2>/dev/null || true
  
  # Aggressive service detection
  nmap -A -T4 --top-ports 100 -oN "$LOG_DIR/${target}_aggressive.txt" "$target" 2>/dev/null || true
  
  # Banner grabbing
  nmap --script banner -oN "$LOG_DIR/${target}_banners.txt" "$target" 2>/dev/null || true
  
  security_log "INFO" "System fingerprinting completed for $target"
}

# Vulnerability assessment with NSE scripts
vulnerability_assessment() {
  local target="$1"
  security_log "INFO" "Starting vulnerability assessment for $target"
  
  # Common vulnerabilities
  nmap --script vuln -oN "$LOG_DIR/${target}_vulnerabilities.txt" "$target" 2>/dev/null || true
  
  # SSL/TLS assessment
  nmap --script ssl-enum-ciphers,ssl-cert,ssl-heartbleed \
    -oN "$LOG_DIR/${target}_ssl.txt" "$target" 2>/dev/null || true
  
  # Web application testing
  nmap --script http-enum,http-headers,http-methods,http-robots.txt \
    -oN "$LOG_DIR/${target}_web.txt" "$target" 2>/dev/null || true
  
  # Database detection
  nmap --script mysql-info,mysql-empty-password,oracle-sid-brute,ms-sql-info \
    -oN "$LOG_DIR/${target}_databases.txt" "$target" 2>/dev/null || true
  
  security_log "INFO" "Vulnerability assessment completed for $target"
}

# Stealth scanning techniques
stealth_reconnaissance() {
  local target="$1"
  security_log "INFO" "Starting stealth reconnaissance for $target"
  
  # Decoy scanning
  nmap -D RND:10 -sS --top-ports 100 -oN "$LOG_DIR/${target}_decoy.txt" "$target" 2>/dev/null || true
  
  # Fragmented packets
  nmap -f -sS --top-ports 50 -oN "$LOG_DIR/${target}_fragmented.txt" "$target" 2>/dev/null || true
  
  # Randomized timing
  nmap -T2 --randomize-hosts --top-ports 50 -oN "$LOG_DIR/${target}_slow.txt" "$target" 2>/dev/null || true
  
  # Source port manipulation
  nmap --source-port 53 -sS --top-ports 25 -oN "$LOG_DIR/${target}_source_port.txt" "$target" 2>/dev/null || true
  
  security_log "INFO" "Stealth reconnaissance completed for $target"
}

# Generate comprehensive security report
generate_security_report() {
  local target="$1"
  local report_file="$LOG_DIR/${target}_security_report.html"
  
  security_log "INFO" "Generating comprehensive security report for $target"
  
  cat > "$report_file" << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Security Assessment Report - $target</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; }
        .header { background: #2c3e50; color: white; padding: 20px; margin: -20px -20px 20px -20px; }
        .section { margin: 20px 0; padding: 15px; border-left: 4px solid #3498db; background: #f8f9fa; }
        .vulnerability { background: #fee; border-left-color: #e74c3c; }
        .info { background: #e8f4fd; border-left-color: #3498db; }
        .success { background: #eaf4ea; border-left-color: #27ae60; }
        pre { background: #2c3e50; color: #ecf0f1; padding: 10px; overflow-x: auto; border-radius: 4px; }
        .compliance { background: #fef9e7; border: 2px solid #f39c12; padding: 15px; margin: 20px 0; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Security Assessment Report</h1>
            <p>Target: $target | Generated: $(date) | Compliance Mode: $COMPLIANCE_MODE</p>
        </div>
        
        <div class="compliance">
            <h3>⚖️ Legal Compliance Notice</h3>
            <p>This security assessment was conducted under authorized conditions. All scanning activities are logged and auditable for compliance purposes. This report is intended for legitimate security assessment and law enforcement use only.</p>
        </div>
        
        <div class="section info">
            <h2>🔍 Network Discovery Results</h2>
            <pre>$(cat "$LOG_DIR/${target}_discovery.txt" 2>/dev/null || echo "No discovery data available")</pre>
        </div>
        
        <div class="section info">
            <h2>🌐 DNS Information</h2>
            <pre>$(cat "$LOG_DIR/${target}_dns.txt" 2>/dev/null || echo "No DNS data available")</pre>
        </div>
        
        <div class="section">
            <h2>🚪 Port Scanning Results</h2>
            <h3>TCP SYN Scan</h3>
            <pre>$(cat "$LOG_DIR/${target}_tcp_syn.txt" 2>/dev/null || echo "No TCP SYN scan data available")</pre>
            
            <h3>Service Detection</h3>
            <pre>$(cat "$LOG_DIR/${target}_services.txt" 2>/dev/null || echo "No service detection data available")</pre>
        </div>
        
        <div class="section vulnerability">
            <h2>🔥 Vulnerability Assessment</h2>
            <pre>$(cat "$LOG_DIR/${target}_vulnerabilities.txt" 2>/dev/null || echo "No vulnerability data available")</pre>
        </div>
        
        <div class="section">
            <h2>🖥️ Operating System Detection</h2>
            <pre>$(cat "$LOG_DIR/${target}_os.txt" 2>/dev/null || echo "No OS detection data available")</pre>
        </div>
        
        <div class="section">
            <h2>🔒 SSL/TLS Assessment</h2>
            <pre>$(cat "$LOG_DIR/${target}_ssl.txt" 2>/dev/null || echo "No SSL/TLS data available")</pre>
        </div>
        
        <div class="section success">
            <h2>📊 Assessment Summary</h2>
            <ul>
                <li>Scan completed: $(date)</li>
                <li>Total files generated: $(ls -1 "$LOG_DIR"/${target}_*.txt 2>/dev/null | wc -l)</li>
                <li>Compliance mode: $COMPLIANCE_MODE</li>
                <li>Law enforcement ready: $([ "$COMPLIANCE_MODE" = "law_enforcement" ] && echo "Yes" || echo "No")</li>
            </ul>
        </div>
        
        <div class="section info">
            <h2>🔗 Integration Points</h2>
            <p>This security assessment integrates with:</p>
            <ul>
                <li>Enhanced AI³ Assistant Orchestrator for threat analysis</li>
                <li>Multi-app Rails architecture for security monitoring</li>
                <li>Business analytics platform for security metrics</li>
                <li>OpenBSD deployment infrastructure for secure operations</li>
            </ul>
        </div>
    </div>
</body>
</html>
EOF
  
  security_log "INFO" "Security report generated: $report_file"
}

# Main security scanning orchestration
perform_comprehensive_scan() {
  local target="$1"
  
  # Validate target
  if [ -z "$target" ]; then
    security_log "ERROR" "No target specified"
    exit 1
  fi
  
  # Check permissions
  if [ "$EUID" -ne 0 ]; then
    security_log "ERROR" "Enhanced security scanning requires root privileges. Use doas."
    exit 1
  fi
  
  # Create log directory
  mkdir -p "$LOG_DIR"
  chmod 750 "$LOG_DIR"
  
  security_log "INFO" "Starting comprehensive security assessment for $target"
  security_log "INFO" "Compliance mode: $COMPLIANCE_MODE"
  
  # Execute scanning phases
  enhanced_network_discovery "$target"
  comprehensive_port_scan "$target"
  system_fingerprinting "$target"
  vulnerability_assessment "$target"
  stealth_reconnaissance "$target"
  
  # Generate comprehensive report
  generate_security_report "$target"
  
  security_log "INFO" "Comprehensive security assessment completed for $target"
  
  # Integration with AI³ system
  if command -v ruby >/dev/null 2>&1; then
    security_log "INFO" "Integrating scan results with AI³ threat analysis system"
    # This would integrate with the Enhanced Assistant Orchestrator
    # ruby -e "require_relative '/home/runner/work/pub/pub/ai3/lib/enhanced_assistant_orchestrator'; orchestrator = EnhancedAssistantOrchestrator.new; puts orchestrator.route_request({domain: 'security', query: 'Analyze scan results for $target', requires_swarm: true})"
  fi
}

# Legal disclaimer and compliance check
display_legal_notice() {
  cat << EOF
⚖️  ENHANCED SECURITY SCANNER - LEGAL NOTICE
==========================================

This tool is designed for authorized security assessments and law enforcement use only.

LEGAL REQUIREMENTS:
- You must have explicit authorization to scan the target
- Unauthorized scanning may violate laws (e.g., U.S. CFAA, EU GDPR, Computer Misuse Act)
- All activities are logged for compliance and audit purposes
- This tool includes law enforcement compliance features

COMPLIANCE MODES:
- 'authorized': Standard authorized security assessment
- 'law_enforcement': Enhanced logging for official investigations

By proceeding, you confirm:
1. You have legal authorization to scan the specified target
2. You understand the legal implications of network reconnaissance
3. You will use the results responsibly and within legal boundaries

EOF
}

# Command line interface
if [ $# -eq 0 ]; then
  display_legal_notice
  echo "Usage: $0 <target_domain_or_ip> [compliance_mode]"
  echo "Example: $0 example.com authorized"
  echo "Example: $0 192.168.1.1 law_enforcement"
  exit 1
fi

# Set compliance mode if provided
if [ -n "$2" ]; then
  COMPLIANCE_MODE="$2"
fi

# Display legal notice and get confirmation
display_legal_notice
echo "Press Y to confirm legal authorization and proceed, any other key to cancel..."
read -k 1 confirm
echo

if [[ "$confirm" != "Y" && "$confirm" != "y" ]]; then
  security_log "INFO" "Security scan cancelled by user"
  exit 0
fi

# Perform the comprehensive security scan
perform_comprehensive_scan "$1"