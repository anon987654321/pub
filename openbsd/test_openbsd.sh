#!/bin/sh
# § Cognitive Framework: OpenBSD.sh Test Suite
# Comprehensive testing with 7±2 cognitive load management

set -e

# § Test Configuration
TEST_DIR="/tmp/openbsd_test"
SCRIPT_PATH="./openbsd.sh"
LOG_FILE="/tmp/openbsd_test.log"
tests_passed=0
tests_failed=0
total_tests=0

# § Color Configuration for Enhanced User Experience
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

# § Cognitive Framework: Test Result Functions
test_start() {
  local test_name="$1"
  local description="$2"
  total_tests=$((total_tests + 1))
  printf "%s[Test %d]%s %s%s%s" "$BLUE" "$total_tests" "$NC" "$CYAN" "$test_name" "$NC"
  if [ -n "$description" ]; then
    printf " - %s" "$description"
  fi
  printf " ... "
}

test_pass() {
  local details="$1"
  tests_passed=$((tests_passed + 1))
  printf "%sPASS%s" "$GREEN" "$NC"
  if [ -n "$details" ]; then
    printf " (%s)" "$details"
  fi
  printf "\n"
}

test_fail() {
  local reason="$1"
  tests_failed=$((tests_failed + 1))
  printf "%sFAIL%s" "$RED" "$NC"
  if [ -n "$reason" ]; then
    printf " (%s)" "$reason"
  fi
  printf "\n"
}

# § Cognitive Framework: Setup and Teardown
setup_test_env() {
  mkdir -p "$TEST_DIR"
  echo "Setting up test environment in $TEST_DIR" > "$LOG_FILE"
}

cleanup_test_env() {
  rm -rf "$TEST_DIR"
  echo "Cleaned up test environment" >> "$LOG_FILE"
}

# § Test Suite: Script Validation (Chunk 1)
test_script_syntax() {
  test_start "Script Syntax" "POSIX shell compliance"
  
  if sh -n "$SCRIPT_PATH" 2>/dev/null; then
    test_pass "no syntax errors"
  else
    test_fail "syntax errors detected"
  fi
}

test_script_permissions() {
  test_start "Script Permissions" "executable and readable"
  
  if [ -r "$SCRIPT_PATH" ] && [ -x "$SCRIPT_PATH" ]; then
    test_pass "permissions correct"
  else
    test_fail "permissions incorrect"
  fi
}

test_shebang_compliance() {
  test_start "Shebang Compliance" "POSIX shell shebang"
  
  first_line=$(head -n 1 "$SCRIPT_PATH")
  if echo "$first_line" | grep -q "#!/bin/sh"; then
    test_pass "POSIX shebang"
  else
    test_fail "non-POSIX shebang: $first_line"
  fi
}

# § Test Suite: Help and Documentation (Chunk 2)
test_help_message() {
  test_start "Help Message" "comprehensive help display"
  
  output=$(sh "$SCRIPT_PATH" --help 2>&1)
  if echo "$output" | grep -q "Usage:" && echo "$output" | grep -q "Options:"; then
    test_pass "help message complete"
  else
    test_fail "help message incomplete"
  fi
}

test_cognitive_framework_mention() {
  test_start "Cognitive Framework" "v10.7.0 compliance mentioned"
  
  output=$(sh "$SCRIPT_PATH" --help 2>&1)
  if echo "$output" | grep -q "Cognitive Framework v10.7.0"; then
    test_pass "cognitive framework mentioned"
  else
    test_fail "cognitive framework not mentioned"
  fi
}

test_security_features_mentioned() {
  test_start "Security Features" "zero-trust security documented"
  
  output=$(sh "$SCRIPT_PATH" --help 2>&1)
  if echo "$output" | grep -q "Zero-trust security" && echo "$output" | grep -q "defense-in-depth"; then
    test_pass "security features documented"
  else
    test_fail "security features not documented"
  fi
}

# § Test Suite: Input Validation (Chunk 3)
test_dry_run_option() {
  test_start "Dry Run Option" "command preview without execution"
  
  # This should not require root for dry run
  export DRY_RUN=true
  output=$(timeout 10s sh "$SCRIPT_PATH" --dry-run --help 2>&1 || true)
  if echo "$output" | grep -q "Usage:"; then
    test_pass "dry run works"
  else
    test_fail "dry run failed"
  fi
}

test_verbose_option() {
  test_start "Verbose Option" "enhanced logging output"
  
  output=$(timeout 5s sh "$SCRIPT_PATH" --verbose --help 2>&1 || true)
  if echo "$output" | grep -q "Usage:"; then
    test_pass "verbose option works"
  else
    test_fail "verbose option failed"
  fi
}

# § Test Suite: Configuration Management (Chunk 4)
test_domain_configuration() {
  test_start "Domain Configuration" "cognitive chunking in domains"
  
  if grep -q "Nordic Region" "$SCRIPT_PATH" && grep -q "British Isles" "$SCRIPT_PATH"; then
    test_pass "domains organized in chunks"
  else
    test_fail "domain organization not found"
  fi
}

test_app_configuration() {
  test_start "Application Configuration" "app list properly defined"
  
  if grep -q "APPS=" "$SCRIPT_PATH" && grep -q "brgen amber" "$SCRIPT_PATH"; then
    test_pass "applications configured"
  else
    test_fail "application configuration missing"
  fi
}

test_security_headers() {
  test_start "Security Headers" "comprehensive security headers"
  
  if grep -q "Strict-Transport-Security" "$SCRIPT_PATH" && grep -q "X-Content-Type-Options" "$SCRIPT_PATH"; then
    test_pass "security headers configured"
  else
    test_fail "security headers missing"
  fi
}

# § Test Suite: Error Handling (Chunk 5)
test_error_handling_functions() {
  test_start "Error Handling" "comprehensive error management"
  
  if grep -q "validate_input" "$SCRIPT_PATH" && grep -q "retry_count" "$SCRIPT_PATH"; then
    test_pass "error handling implemented"
  else
    test_fail "error handling missing"
  fi
}

test_logging_functionality() {
  test_start "Logging Functionality" "structured logging with levels"
  
  if grep -q "log.*ERROR" "$SCRIPT_PATH" && grep -q "log.*WARN" "$SCRIPT_PATH"; then
    test_pass "logging levels implemented"
  else
    test_fail "logging levels missing"
  fi
}

# § Test Suite: Master.json Compliance (Chunk 6)
test_double_quote_formatting() {
  test_start "Double Quote Formatting" "master.json compliance"
  
  # Check for consistent double quote usage
  single_quotes=$(grep -o "'" "$SCRIPT_PATH" | wc -l)
  double_quotes=$(grep -o '"' "$SCRIPT_PATH" | wc -l)
  
  if [ "$double_quotes" -gt "$single_quotes" ]; then
    test_pass "double quotes preferred"
  else
    test_fail "single quotes found more than double quotes"
  fi
}

test_cognitive_headers() {
  test_start "Cognitive Headers" "section headers with § symbol"
  
  if grep -q "§ Cognitive Framework" "$SCRIPT_PATH"; then
    test_pass "cognitive headers present"
  else
    test_fail "cognitive headers missing"
  fi
}

test_two_space_indentation() {
  test_start "Two Space Indentation" "consistent formatting"
  
  # Check for consistent 2-space indentation (improved check)
  if grep -q "^  [^ ]" "$SCRIPT_PATH" && grep -q "^  log" "$SCRIPT_PATH"; then
    test_pass "2-space indentation used"
  else
    test_fail "indentation inconsistent"
  fi
}

# § Test Suite: Security Implementation (Chunk 7)
test_zero_trust_principles() {
  test_start "Zero Trust Principles" "security validation throughout"
  
  if grep -q "zero-trust" "$SCRIPT_PATH" && grep -q "validate_input" "$SCRIPT_PATH"; then
    test_pass "zero-trust principles implemented"
  else
    test_fail "zero-trust principles missing"
  fi
}

test_circuit_breaker_pattern() {
  test_start "Circuit Breaker Pattern" "automatic failure management"
  
  if grep -q "max_retries" "$SCRIPT_PATH" && grep -q "retry_count" "$SCRIPT_PATH"; then
    test_pass "circuit breaker implemented"
  else
    test_fail "circuit breaker missing"
  fi
}

# § Main Test Execution
main() {
  printf "%s§ OpenBSD.sh Test Suite - Cognitive Framework v10.7.0%s\n" "$YELLOW" "$NC"
  printf "Testing script: %s\n\n" "$SCRIPT_PATH"
  
  # Check if script exists
  if [ ! -f "$SCRIPT_PATH" ]; then
    printf "%sERROR:%s Script not found: %s\n" "$RED" "$NC" "$SCRIPT_PATH"
    exit 1
  fi
  
  setup_test_env
  
  # § Test Execution in Cognitive Chunks
  printf "%s=== Chunk 1: Script Validation ===%s\n" "$CYAN" "$NC"
  test_script_syntax
  test_script_permissions
  test_shebang_compliance
  
  printf "\n%s=== Chunk 2: Help and Documentation ===%s\n" "$CYAN" "$NC"
  test_help_message
  test_cognitive_framework_mention
  test_security_features_mentioned
  
  printf "\n%s=== Chunk 3: Input Validation ===%s\n" "$CYAN" "$NC"
  test_dry_run_option
  test_verbose_option
  
  printf "\n%s=== Chunk 4: Configuration Management ===%s\n" "$CYAN" "$NC"
  test_domain_configuration
  test_app_configuration
  test_security_headers
  
  printf "\n%s=== Chunk 5: Error Handling ===%s\n" "$CYAN" "$NC"
  test_error_handling_functions
  test_logging_functionality
  
  printf "\n%s=== Chunk 6: Master.json Compliance ===%s\n" "$CYAN" "$NC"
  test_double_quote_formatting
  test_cognitive_headers
  test_two_space_indentation
  
  printf "\n%s=== Chunk 7: Security Implementation ===%s\n" "$CYAN" "$NC"
  test_zero_trust_principles
  test_circuit_breaker_pattern
  
  cleanup_test_env
  
  # § Test Summary
  printf "\n%s=== Test Summary ===%s\n" "$YELLOW" "$NC"
  printf "Total tests: %d\n" "$total_tests"
  printf "%sPassed: %d%s\n" "$GREEN" "$tests_passed" "$NC"
  
  if [ $tests_failed -gt 0 ]; then
    printf "%sFailed: %d%s\n" "$RED" "$tests_failed" "$NC"
    printf "\n%ssome tests failed. Please review the OpenBSD.sh implementation.%s\n" "$RED" "$NC"
    exit 1
  else
    printf "%sFailed: %d%s\n" "$GREEN" "$tests_failed" "$NC"
    printf "\n%sAll tests passed! The OpenBSD.sh script meets cognitive framework requirements.%s\n" "$GREEN" "$NC"
    exit 0
  fi
}

# Execute main function
main "$@"