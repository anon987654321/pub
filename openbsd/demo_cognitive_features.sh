#!/bin/sh
set -eu

# demo_cognitive_features.sh - Demonstrates cognitive architecture features of nmap.sh
# Usage: sh demo_cognitive_features.sh

# Colors for output
if [ -t 1 ]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  BLUE='\033[0;34m'
  CYAN='\033[0;36m'
  BOLD='\033[1m'
  NC='\033[0m'
else
  RED=''
  GREEN=''
  YELLOW=''
  BLUE=''
  CYAN=''
  BOLD=''
  NC=''
fi

echo "${BOLD}=== Cognitive Architecture Demo for nmap.sh ===${NC}"
echo ""
echo "This demo shows the cognitive features implemented in the improved nmap.sh"
echo "tool compared to the original deep_nmap_scan.sh."
echo ""

# Demo 1: Cognitive Load Management
echo "${CYAN}Demo 1: Cognitive Load Management${NC}"
echo "The tool tracks and manages cognitive load using the 7±2 rule from cognitive science."
echo ""
echo "${YELLOW}Feature:${NC} Memory chunk management with automatic compression"
echo "${YELLOW}Benefit:${NC} Prevents cognitive overload during long scans"
echo "${YELLOW}Implementation:${NC} Automatic reduction when >7 chunks in working memory"
echo ""

# Demo 2: Progressive Complexity Disclosure
echo "${CYAN}Demo 2: Progressive Complexity Disclosure${NC}"
echo "Complex scanning broken into 7 manageable phases with clear boundaries."
echo ""
echo "${YELLOW}Phases:${NC}"
echo "  1. Dependency Validation  (setup validation)"
echo "  2. DNS Resolution         (target preparation)"
echo "  3. Host Discovery         (basic reconnaissance)"
echo "  4. Port Discovery         (attack surface mapping)"
echo "  5. Service Analysis       (deep inspection)"
echo "  6. Vulnerability Assessment (security evaluation)"
echo "  7. Report Generation      (synthesis and presentation)"
echo ""

# Demo 3: Error Handling with Graceful Degradation
echo "${CYAN}Demo 3: Error Handling with Graceful Degradation${NC}"
echo "Robust error handling that continues operation with reduced functionality."
echo ""
echo "${YELLOW}Example Error Scenarios:${NC}"
echo "• Missing nmap → Critical error with installation guidance"
echo "• Missing drill → Fallback to dig, then host, then nslookup"
echo "• Network timeout → Retry with alternative methods"
echo "• Permission denied → Clear guidance on doas configuration"
echo ""

# Demo 4: Cognitive Recovery Protocols
echo "${CYAN}Demo 4: Cognitive Recovery Protocols${NC}"
echo "Monitors cognitive state and implements recovery when needed."
echo ""
echo "${YELLOW}Recovery Features:${NC}"
echo "• Context switch delays (2s between phases)"
echo "• Progress feedback to maintain situational awareness"
echo "• Memory chunk compression when limits exceeded"
echo "• Clear phase boundaries to reduce mental overhead"
echo ""

# Demo 5: Multi-method Resilience
echo "${CYAN}Demo 5: Multi-method Resilience${NC}"
echo "Multiple techniques for each operation to ensure success."
echo ""
echo "${YELLOW}DNS Resolution Fallback Chain:${NC}"
echo "  drill (OpenBSD native) → dig → host → nslookup"
echo ""
echo "${YELLOW}Host Discovery Methods:${NC}"
echo "  1. Multi-protocol discovery (TCP SYN + UDP + ICMP)"
echo "  2. HTTP-focused discovery (ports 80, 443)"
echo "  3. Basic ICMP ping"
echo ""

# Demo 6: Professional Reporting
echo "${CYAN}Demo 6: Professional Reporting${NC}"
echo "Structured output with executive summaries and actionable insights."
echo ""
echo "${YELLOW}Output Structure:${NC}"
echo "  nmap_scan_target_timestamp/"
echo "  ├── raw/                    # Technical data"
echo "  ├── executive_summary.txt   # Executive overview"
echo "  └── index.md               # Navigation aid"
echo ""
echo "${YELLOW}Executive Summary Includes:${NC}"
echo "• Risk assessment (HIGH/MEDIUM/LOW)"
echo "• Key metrics (ports, services, vulnerabilities)"
echo "• Next steps recommendations"
echo "• Scan metadata and duration"
echo ""

# Comparison with old script
echo "${CYAN}Comparison with deep_nmap_scan.sh:${NC}"
echo ""
printf "%-25s %-20s %-20s\n" "Feature" "deep_nmap_scan.sh" "nmap.sh"
printf "%-25s %-20s %-20s\n" "-------" "----------------" "-------"
printf "%-25s %-20s %-20s\n" "Shell Compatibility" "zsh only" "POSIX (all shells)"
printf "%-25s %-20s %-20s\n" "Cognitive Architecture" "None" "Full 7±2 management"
printf "%-25s %-20s %-20s\n" "Error Handling" "Basic" "Comprehensive"
printf "%-25s %-20s %-20s\n" "Progress Feedback" "Minimal" "Real-time cognitive"
printf "%-25s %-20s %-20s\n" "Dependency Checking" "None" "Full validation"
printf "%-25s %-20s %-20s\n" "Professional Reports" "Basic logs" "Executive summaries"
printf "%-25s %-20s %-20s\n" "OpenBSD Integration" "Partial" "Native optimized"
printf "%-25s %-20s %-20s\n" "Documentation" "Norwegian" "English + comprehensive"
echo ""

# Testing demonstration
echo "${CYAN}Live Demonstration:${NC}"
echo "Run the following commands to see cognitive features in action:"
echo ""
echo "${GREEN}1. Basic help and validation:${NC}"
echo "   sh nmap.sh"
echo ""
echo "${GREEN}2. Dependency checking:${NC}"
echo "   sh nmap.sh example.com"
echo "   (Shows cognitive load management and progress tracking)"
echo ""
echo "${GREEN}3. Invalid input handling:${NC}"
echo "   sh nmap.sh 'invalid@target!'"
echo "   (Demonstrates error handling with helpful suggestions)"
echo ""
echo "${GREEN}4. Run validation tests:${NC}"
echo "   sh test_nmap.sh"
echo "   (Validates all cognitive architecture features)"
echo ""

echo "${BOLD}=== Cognitive Benefits Summary ===${NC}"
echo ""
echo "${GREEN}✓${NC} Reduced cognitive load through chunking"
echo "${GREEN}✓${NC} Clear progress feedback maintains flow state"
echo "${GREEN}✓${NC} Error recovery prevents task abandonment"
echo "${GREEN}✓${NC} Professional output supports decision-making"
echo "${GREEN}✓${NC} POSIX compliance ensures broad compatibility"
echo "${GREEN}✓${NC} OpenBSD optimization respects system design"
echo ""
echo "The improved nmap.sh tool transforms network scanning from a"
echo "cognitively demanding task into a managed, professional workflow."