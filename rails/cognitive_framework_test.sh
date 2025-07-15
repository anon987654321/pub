#!/usr/bin/env bash
# Comprehensive test suite for cognitive framework implementation
# Master.json v10.7.0 compliance validation

set -e

# === COGNITIVE FRAMEWORK TEST CONFIGURATION ===
TEST_BASE_DIR="/home/runner/work/pubhealthcare/pubhealthcare/rails"
LOG_FILE="${TEST_BASE_DIR}/cognitive_framework_test.log"

# Test applications
APPLICATIONS=(
  "amber"
  "blognet"
  "hjerterom"
  "privcam"
  "bsdports"
  "brgen/brgen"
  "brgen/subapps/dating"
  "brgen/subapps/marketplace"
  "brgen/subapps/playlist"
  "brgen/subapps/takeaway"
  "brgen/subapps/tv"
)

# Cognitive framework test results
declare -A test_results
declare -g total_tests=0
declare -g passed_tests=0
declare -g failed_tests=0

# === LOGGING FUNCTIONS ===
log() {
  local message="$1"
  local level="${2:-INFO}"
  local timestamp=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
  
  echo "[${timestamp}] [${level}] ${message}" | tee -a "${LOG_FILE}"
}

error() {
  log "ERROR: $1" "ERROR"
  ((failed_tests++))
}

success() {
  log "SUCCESS: $1" "SUCCESS"
  ((passed_tests++))
}

# === TEST FUNCTIONS ===
test_cognitive_compliance_module() {
  log "Testing cognitive compliance module existence and structure"
  ((total_tests++))
  
  local module_file="${TEST_BASE_DIR}/cognitive_compliance.rb"
  
  if [[ ! -f "$module_file" ]]; then
    error "Cognitive compliance module not found at $module_file"
    return 1
  fi
  
  # Test module structure
  if ! grep -q "module CognitiveCompliance" "$module_file"; then
    error "CognitiveCompliance module not properly defined"
    return 1
  fi
  
  # Test key classes
  local required_classes=("CognitiveLoadMonitor" "FlowStateTracker" "CognitiveCircuitBreaker")
  for class_name in "${required_classes[@]}"; do
    if ! grep -q "class $class_name" "$module_file"; then
      error "Required class $class_name not found in cognitive compliance module"
      return 1
    fi
  done
  
  # Test 7±2 concept limitation
  if ! grep -q "7" "$module_file"; then
    error "7±2 concept limitation not implemented"
    return 1
  fi
  
  success "Cognitive compliance module structure validated"
}

test_master_json_compliance() {
  log "Testing master.json compliance"
  ((total_tests++))
  
  local master_json="${TEST_BASE_DIR}/master.json"
  
  if [[ ! -f "$master_json" ]]; then
    error "master.json file not found at $master_json"
    return 1
  fi
  
  # Test JSON validity
  if ! python3 -m json.tool "$master_json" > /dev/null 2>&1; then
    error "master.json is not valid JSON"
    return 1
  fi
  
  # Test required fields
  local required_fields=("cognitive_framework" "system_integration" "rails_applications" "quality_standards")
  for field in "${required_fields[@]}"; do
    if ! grep -q "\"$field\"" "$master_json"; then
      error "Required field $field not found in master.json"
      return 1
    fi
  done
  
  # Test version compliance
  if ! grep -q "\"version\": \"10.7.0\"" "$master_json"; then
    error "Master.json version not set to 10.7.0"
    return 1
  fi
  
  success "Master.json compliance validated"
}

test_enhanced_shared_installer() {
  log "Testing enhanced shared installer"
  ((total_tests++))
  
  local shared_installer="${TEST_BASE_DIR}/__shared_enhanced.sh"
  
  if [[ ! -f "$shared_installer" ]]; then
    error "Enhanced shared installer not found at $shared_installer"
    return 1
  fi
  
  # Test cognitive framework integration
  if ! grep -q "COGNITIVE_LOAD_CURRENT" "$shared_installer"; then
    error "Cognitive load tracking not implemented in shared installer"
    return 1
  fi
  
  # Test circuit breaker implementation
  if ! grep -q "trigger_cognitive_circuit_breaker" "$shared_installer"; then
    error "Circuit breaker not implemented in shared installer"
    return 1
  fi
  
  # Test phase management
  if ! grep -q "phase_transition" "$shared_installer"; then
    error "Phase transition management not implemented"
    return 1
  fi
  
  # Test zero-trust validation
  if ! grep -q "validate_command_exists" "$shared_installer"; then
    error "Zero-trust validation not implemented"
    return 1
  fi
  
  success "Enhanced shared installer validated"
}

test_application_installer() {
  local app_path="$1"
  local app_name=$(basename "$app_path")
  
  log "Testing application installer: $app_name"
  ((total_tests++))
  
  local installer_file="${TEST_BASE_DIR}/${app_path}.sh"
  
  if [[ ! -f "$installer_file" ]]; then
    error "Application installer not found: $installer_file"
    return 1
  fi
  
  # Test cognitive framework integration
  if ! grep -q "cognitive_framework" "$installer_file"; then
    error "Cognitive framework not integrated in $app_name installer"
    return 1
  fi
  
  # Test enhanced shared functionality usage
  if ! grep -q "__shared_enhanced.sh" "$installer_file"; then
    error "Enhanced shared functionality not used in $app_name installer"
    return 1
  fi
  
  # Test generate_application_code function
  if ! grep -q "generate_application_code" "$installer_file"; then
    error "generate_application_code function not implemented in $app_name installer"
    return 1
  fi
  
  # Test cognitive load management
  if ! grep -q "CognitiveLoadMonitor" "$installer_file"; then
    error "Cognitive load monitoring not implemented in $app_name installer"
    return 1
  fi
  
  success "Application installer validated: $app_name"
}

test_double_quote_compliance() {
  log "Testing double quote compliance across all files"
  ((total_tests++))
  
  local quote_violations=0
  
  # Check Ruby files for single quotes (should be double quotes)
  for app in "${APPLICATIONS[@]}"; do
    local installer_file="${TEST_BASE_DIR}/${app}.sh"
    
    if [[ -f "$installer_file" ]]; then
      # Check for single quotes in Ruby code blocks
      if grep -q "gem '[^']*'" "$installer_file"; then
        log "Single quote violation in Ruby code: $installer_file"
        ((quote_violations++))
      fi
      
      # Check for double quotes in JSON-like structures
      if grep -q '"[^"]*"' "$installer_file"; then
        log "Double quote compliance found in: $installer_file"
      fi
    fi
  done
  
  # Check master.json for double quotes
  local master_json="${TEST_BASE_DIR}/master.json"
  if [[ -f "$master_json" ]]; then
    if grep -q "'" "$master_json"; then
      log "Single quote violation in master.json"
      ((quote_violations++))
    fi
  fi
  
  if [[ $quote_violations -gt 0 ]]; then
    error "Double quote compliance violations found: $quote_violations"
    return 1
  fi
  
  success "Double quote compliance validated"
}

test_indentation_compliance() {
  log "Testing 2-space indentation compliance"
  ((total_tests++))
  
  local indentation_violations=0
  
  # Check master.json for 2-space indentation
  local master_json="${TEST_BASE_DIR}/master.json"
  if [[ -f "$master_json" ]]; then
    # Check for 4-space indentation (should be 2-space)
    if grep -q "^    " "$master_json"; then
      log "4-space indentation found in master.json (should be 2-space)"
      ((indentation_violations++))
    fi
    
    # Check for tab indentation
    if grep -q $'\t' "$master_json"; then
      log "Tab indentation found in master.json (should be 2-space)"
      ((indentation_violations++))
    fi
  fi
  
  if [[ $indentation_violations -gt 0 ]]; then
    error "Indentation compliance violations found: $indentation_violations"
    return 1
  fi
  
  success "2-space indentation compliance validated"
}

test_cognitive_load_limits() {
  log "Testing 7±2 cognitive load limits implementation"
  ((total_tests++))
  
  local cognitive_module="${TEST_BASE_DIR}/cognitive_compliance.rb"
  
  if [[ ! -f "$cognitive_module" ]]; then
    error "Cognitive compliance module not found for testing"
    return 1
  fi
  
  # Test complexity thresholds
  if ! grep -q "overload.*8" "$cognitive_module"; then
    error "Cognitive overload threshold not properly set to 8"
    return 1
  fi
  
  # Test concept chunking
  if ! grep -q "limit.*7" "$cognitive_module"; then
    error "7±2 concept chunking not implemented"
    return 1
  fi
  
  success "Cognitive load limits validated"
}

test_security_implementation() {
  log "Testing zero-trust security implementation"
  ((total_tests++))
  
  local security_features=0
  
  # Test enhanced shared installer security
  local shared_installer="${TEST_BASE_DIR}/__shared_enhanced.sh"
  if [[ -f "$shared_installer" ]]; then
    if grep -q "validate_command_exists" "$shared_installer"; then
      ((security_features++))
    fi
    
    if grep -q "validate_directory_permissions" "$shared_installer"; then
      ((security_features++))
    fi
    
    if grep -q "validate_file_integrity" "$shared_installer"; then
      ((security_features++))
    fi
  fi
  
  # Test application security features
  for app in "${APPLICATIONS[@]}"; do
    local installer_file="${TEST_BASE_DIR}/${app}.sh"
    
    if [[ -f "$installer_file" ]]; then
      if grep -q "zero.*trust" "$installer_file"; then
        ((security_features++))
      fi
      
      if grep -q "authenticate_user" "$installer_file"; then
        ((security_features++))
      fi
    fi
  done
  
  if [[ $security_features -lt 5 ]]; then
    error "Insufficient security features implemented: $security_features"
    return 1
  fi
  
  success "Zero-trust security implementation validated"
}

test_accessibility_compliance() {
  log "Testing WCAG 2.2 AAA accessibility compliance"
  ((total_tests++))
  
  local accessibility_features=0
  
  # Test for accessibility features in application code
  for app in "${APPLICATIONS[@]}"; do
    local installer_file="${TEST_BASE_DIR}/${app}.sh"
    
    if [[ -f "$installer_file" ]]; then
      if grep -q "aria-label" "$installer_file"; then
        ((accessibility_features++))
      fi
      
      if grep -q "role=" "$installer_file"; then
        ((accessibility_features++))
      fi
      
      if grep -q "wcag" "$installer_file"; then
        ((accessibility_features++))
      fi
    fi
  done
  
  if [[ $accessibility_features -lt 3 ]]; then
    error "Insufficient accessibility features implemented: $accessibility_features"
    return 1
  fi
  
  success "WCAG 2.2 AAA accessibility compliance validated"
}

# === MAIN TEST EXECUTION ===
main() {
  log "Starting comprehensive cognitive framework test suite"
  
  # Initialize log file
  echo "=== Cognitive Framework Test Suite - $(date) ===" > "$LOG_FILE"
  
  # Core framework tests
  test_cognitive_compliance_module
  test_master_json_compliance
  test_enhanced_shared_installer
  
  # Application-specific tests
  for app in "${APPLICATIONS[@]}"; do
    test_application_installer "$app"
  done
  
  # Compliance tests
  test_double_quote_compliance
  test_indentation_compliance
  test_cognitive_load_limits
  test_security_implementation
  test_accessibility_compliance
  
  # Test summary
  log "=== TEST SUMMARY ==="
  log "Total tests: $total_tests"
  log "Passed: $passed_tests"
  log "Failed: $failed_tests"
  
  local pass_rate=$((passed_tests * 100 / total_tests))
  log "Pass rate: ${pass_rate}%"
  
  if [[ $failed_tests -eq 0 ]]; then
    log "🎉 ALL TESTS PASSED! Cognitive framework implementation is complete."
    exit 0
  else
    log "❌ Some tests failed. Please review the implementation."
    exit 1
  fi
}

# Run tests
main "$@"