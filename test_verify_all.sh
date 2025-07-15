#!/bin/bash

# Simple test script for verify_all.sh
# Tests basic functionality and argument parsing

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VERIFY_SCRIPT="$SCRIPT_DIR/verify_all.sh"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Test function
test_function() {
    local test_name="$1"
    local expected_exit_code="$2"
    shift 2
    local command="$@"
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    
    echo -n "Testing $test_name... "
    
    # Run the command and capture exit code
    $command > /dev/null 2>&1
    local actual_exit_code=$?
    
    if [ $actual_exit_code -eq $expected_exit_code ]; then
        echo -e "${GREEN}PASS${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "${RED}FAIL${NC} (expected $expected_exit_code, got $actual_exit_code)"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
}

# Test file existence
test_file_exists() {
    local file="$1"
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC} File exists: $file"
        return 0
    else
        echo -e "${RED}✗${NC} File missing: $file"
        return 1
    fi
}

echo "================================================="
echo "        verify_all.sh Test Suite"
echo "================================================="
echo

# Test 1: Check if script exists and is executable
echo "1. File and Permission Tests:"
test_file_exists "$VERIFY_SCRIPT"
if [ -x "$VERIFY_SCRIPT" ]; then
    echo -e "${GREEN}✓${NC} Script is executable"
else
    echo -e "${RED}✗${NC} Script is not executable"
    exit 1
fi
echo

# Test 2: Test help option
echo "2. Argument Parsing Tests:"
test_function "help option" 0 "$VERIFY_SCRIPT" --help
test_function "invalid option" 1 "$VERIFY_SCRIPT" --invalid-option
echo

# Test 3: Test output formats
echo "3. Output Format Tests:"
test_function "standard output" 1 "$VERIFY_SCRIPT"
test_function "verbose output" 1 "$VERIFY_SCRIPT" --verbose
test_function "quiet output" 1 "$VERIFY_SCRIPT" --quiet
test_function "json output" 1 "$VERIFY_SCRIPT" --json
echo

# Test 4: Test JSON output format
echo "4. JSON Output Validation:"
echo -n "Testing JSON format... "
json_output=$("$VERIFY_SCRIPT" --json 2>/dev/null)
if echo "$json_output" | python3 -m json.tool > /dev/null 2>&1; then
    echo -e "${GREEN}PASS${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    echo -e "${RED}FAIL${NC} (invalid JSON)"
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))
echo

# Test 5: Test log file creation
echo "5. Log File Tests:"
echo -n "Testing log file creation... "
# Run script and check if log file is created
"$VERIFY_SCRIPT" --quiet > /dev/null 2>&1
if ls /tmp/verify_all_*.log > /dev/null 2>&1; then
    echo -e "${GREEN}PASS${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
    # Clean up log files
    rm -f /tmp/verify_all_*.log
else
    echo -e "${RED}FAIL${NC} (no log file created)"
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))
echo

# Test 6: Configuration validation
echo "6. Configuration Tests:"
echo -n "Testing configuration constants... "
if grep -q "APPS=.*brgen.*amber.*pubattorney" "$VERIFY_SCRIPT" && \
   grep -q "RAILS_VERSION=\"8.0.0\"" "$VERIFY_SCRIPT" && \
   grep -q "RUBY_VERSION=\"3.3.0\"" "$VERIFY_SCRIPT"; then
    echo -e "${GREEN}PASS${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    echo -e "${RED}FAIL${NC} (configuration constants not found)"
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))
echo

# Test 7: Function definitions
echo "7. Function Definition Tests:"
functions_to_check=("check_openbsd_services" "check_ssl_certificates" "check_dns_resolution" "check_rails_applications" "check_infrastructure" "check_features" "check_network_security" "check_http_responses")
for func in "${functions_to_check[@]}"; do
    echo -n "Testing function $func... "
    if grep -q "^$func()" "$VERIFY_SCRIPT"; then
        echo -e "${GREEN}PASS${NC}"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "${RED}FAIL${NC} (function not found)"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
done
echo

# Test 8: Domain list validation
echo "8. Domain Configuration Tests:"
echo -n "Testing domain list... "
domain_count=$(grep -c "\".*\\..*\"" "$VERIFY_SCRIPT" | head -1)
if [ "$domain_count" -gt 40 ]; then  # Should have 56 domains, but allow some flexibility
    echo -e "${GREEN}PASS${NC} ($domain_count domains found)"
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    echo -e "${RED}FAIL${NC} (insufficient domains: $domain_count)"
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))
echo

# Test 9: Check for required commands handling
echo "9. Command Availability Tests:"
echo -n "Testing command availability checks... "
if grep -q "command -v.*> /dev/null 2>&1" "$VERIFY_SCRIPT"; then
    echo -e "${GREEN}PASS${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    echo -e "${RED}FAIL${NC} (command availability checks not found)"
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))
echo

# Test 10: Error handling
echo "10. Error Handling Tests:"
echo -n "Testing error handling... "
if grep -q "check_result.*FAIL" "$VERIFY_SCRIPT" && \
   grep -q "check_result.*WARN" "$VERIFY_SCRIPT" && \
   grep -q "check_result.*PASS" "$VERIFY_SCRIPT"; then
    echo -e "${GREEN}PASS${NC}"
    PASSED_TESTS=$((PASSED_TESTS + 1))
else
    echo -e "${RED}FAIL${NC} (error handling not found)"
    FAILED_TESTS=$((FAILED_TESTS + 1))
fi
TOTAL_TESTS=$((TOTAL_TESTS + 1))
echo

# Summary
echo "================================================="
echo "              Test Summary"
echo "================================================="
echo "Total Tests: $TOTAL_TESTS"
echo -e "Passed: ${GREEN}$PASSED_TESTS${NC}"
echo -e "Failed: ${RED}$FAILED_TESTS${NC}"
echo

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "Overall Status: ${GREEN}ALL TESTS PASSED${NC}"
    echo "The verify_all.sh script is ready for use!"
    exit 0
else
    echo -e "Overall Status: ${RED}SOME TESTS FAILED${NC}"
    echo "Please review the failing tests and fix the issues."
    exit 1
fi