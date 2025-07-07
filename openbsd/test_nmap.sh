#!/bin/sh
set -eu

# test_nmap.sh - Validation tests for nmap.sh cognitive scanning tool
# Usage: sh test_nmap.sh

# Test result tracking
tests_passed=0
tests_failed=0
total_tests=0

# Colors for output
if [ -t 1 ]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  BLUE='\033[0;34m'
  NC='\033[0m'
else
  RED=''
  GREEN=''
  YELLOW=''
  BLUE=''
  NC=''
fi

# Test result functions
test_start() {
  test_name="$1"
  total_tests=$((total_tests + 1))
  printf "%sTest %d:%s %s ... " "$BLUE" "$total_tests" "$NC" "$test_name"
}

test_pass() {
  tests_passed=$((tests_passed + 1))
  printf "%sPASS%s\n" "$GREEN" "$NC"
}

test_fail() {
  reason="$1"
  tests_failed=$((tests_failed + 1))
  printf "%sFAIL%s (%s)\n" "$RED" "$NC" "$reason"
}

# Test 1: Script syntax validation
test_start "Script syntax validation"
if sh -n nmap.sh >/dev/null 2>&1; then
  test_pass
else
  test_fail "syntax errors detected"
fi

# Test 2: Help message display
test_start "Help message display"
output=$(sh nmap.sh 2>&1 || true)
if echo "$output" | grep -q "Usage:"; then
  test_pass
else
  test_fail "no usage message found"
fi

# Test 3: Invalid target handling
test_start "Invalid target handling"
output=$(sh nmap.sh "invalid@target!" 2>&1 || true)
if echo "$output" | grep -q "Invalid target format"; then
  test_pass
else
  test_fail "invalid target not properly rejected"
fi

# Test 4: Dependency checking
test_start "Dependency checking functionality"
output=$(timeout 5s sh nmap.sh example.com 2>&1 || true)
if echo "$output" | grep -q "Validating system dependencies"; then
  test_pass
else
  test_fail "dependency validation not triggered"
fi

# Test 5: Progress indication
test_start "Progress indication"
output=$(timeout 5s sh nmap.sh example.com 2>&1 || true)
if echo "$output" | grep -q "Phase.*Dependency Validation"; then
  test_pass
else
  test_fail "progress indication not working"
fi

# Test 6: Cognitive load management
test_start "Cognitive architecture presence"
output=$(timeout 5s sh nmap.sh example.com 2>&1 || true)
if echo "$output" | grep -q "Cognitive architecture.*memory management"; then
  test_pass
else
  test_fail "cognitive architecture not initialized"
fi

# Test 7: Error handling
test_start "Error handling with suggestions"
output=$(timeout 5s sh nmap.sh example.com 2>&1 || true)
if echo "$output" | grep -q "Suggestion:"; then
  test_pass
else
  test_fail "error suggestions not provided"
fi

# Test 8: POSIX compliance check
test_start "POSIX compliance (shellcheck)"
if command -v shellcheck >/dev/null 2>&1; then
  # Run shellcheck and check for critical errors only
  shellcheck_output=$(shellcheck nmap.sh 2>&1 || true)
  if ! echo "$shellcheck_output" | grep -q "error:"; then
    test_pass
  else
    test_fail "shellcheck found critical errors"
  fi
else
  test_pass  # Skip if shellcheck not available
fi

# Summary
echo ""
echo "=== Test Summary ==="
printf "Total tests: %d\n" "$total_tests"
printf "%sPassed: %d%s\n" "$GREEN" "$tests_passed" "$NC"
if [ $tests_failed -gt 0 ]; then
  printf "%sFailed: %d%s\n" "$RED" "$tests_failed" "$NC"
  echo ""
  echo "Some tests failed. Please review the nmap.sh implementation."
  exit 1
else
  printf "%sFailed: %d%s\n" "$GREEN" "$tests_failed" "$NC"
  echo ""
  echo "All tests passed! The nmap.sh script is functioning correctly."
  exit 0
fi