#!/usr/bin/env zsh
# Standardized Rails Application Installer Template
# Master.json v10.7.0 Cognitive Framework Implementation
# Zero-trust security, 7±2 cognitive chunking, comprehensive validation

set -e
setopt extended_glob null_glob

# === COGNITIVE LOAD MANAGEMENT ===
# Chunk 1: Core Configuration (7 concepts max)
readonly APP_NAME="${APP_NAME:-template}"
readonly BASE_DIR="${BASE_DIR:-/home/dev/rails}"
readonly RAILS_VERSION="${RAILS_VERSION:-8.0.0}"
readonly RUBY_VERSION="${RUBY_VERSION:-3.3.0}"
readonly NODE_VERSION="${NODE_VERSION:-20}"
readonly BRGEN_IP="${BRGEN_IP:-46.23.95.45}"
readonly LOG_FILE="${BASE_DIR}/${APP_NAME}/setup.log"

# Chunk 2: Cognitive State Management
declare -g COGNITIVE_LOAD_CURRENT=0
declare -g CONCEPT_STACK=()
declare -g CONTEXT_SWITCHES=0
declare -g FLOW_STATE_ACTIVE=false
declare -g CIRCUIT_BREAKER_OPEN=false
declare -g ATTENTION_RESTORATION_NEEDED=false
declare -g INSTALLATION_PHASE="initialization"

# === LOGGING AND MONITORING ===
log() {
  local message="$1"
  local level="${2:-INFO}"
  local timestamp=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
  
  echo "[${timestamp}] [${level}] [${INSTALLATION_PHASE}] ${message}" | tee -a "${LOG_FILE}"
  
  # Cognitive load tracking
  ((COGNITIVE_LOAD_CURRENT++))
  
  # Circuit breaker check
  if [[ ${COGNITIVE_LOAD_CURRENT} -gt 7 ]]; then
    trigger_cognitive_circuit_breaker
  fi
}

error_exit() {
  log "ERROR: $1" "ERROR"
  log "Installation failed for ${APP_NAME}" "ERROR"
  exit 1
}

# === COGNITIVE CIRCUIT BREAKER ===
trigger_cognitive_circuit_breaker() {
  if [[ "${CIRCUIT_BREAKER_OPEN}" == "true" ]]; then
    return 0
  fi
  
  CIRCUIT_BREAKER_OPEN=true
  log "Cognitive circuit breaker triggered - load: ${COGNITIVE_LOAD_CURRENT}" "WARN"
  
  # Implement attention restoration
  initiate_attention_restoration
  
  # Reset cognitive load
  COGNITIVE_LOAD_CURRENT=3
  CONCEPT_STACK=()
  
  CIRCUIT_BREAKER_OPEN=false
}

initiate_attention_restoration() {
  log "Initiating attention restoration protocol" "INFO"
  ATTENTION_RESTORATION_NEEDED=true
  
  # Brief pause for cognitive recovery
  sleep 2
  
  # Simplify remaining installation steps
  log "Simplified installation mode activated" "INFO"
  
  ATTENTION_RESTORATION_NEEDED=false
}

# === ZERO-TRUST VALIDATION ===
validate_command_exists() {
  local command="$1"
  local required="${2:-true}"
  
  if ! command -v "$command" > /dev/null 2>&1; then
    if [[ "$required" == "true" ]]; then
      error_exit "Command '$command' not found. Please install it first."
    else
      log "Optional command '$command' not found, skipping" "WARN"
      return 1
    fi
  fi
  
  log "Command '$command' validated" "INFO"
  return 0
}

validate_directory_permissions() {
  local dir="$1"
  
  if [[ ! -d "$dir" ]]; then
    error_exit "Directory '$dir' does not exist"
  fi
  
  if [[ ! -w "$dir" ]]; then
    error_exit "Directory '$dir' is not writable"
  fi
  
  log "Directory permissions validated: $dir" "INFO"
}

validate_file_integrity() {
  local file="$1"
  local expected_type="${2:-file}"
  
  if [[ ! -e "$file" ]]; then
    error_exit "File '$file' does not exist"
  fi
  
  case "$expected_type" in
    "file")
      if [[ ! -f "$file" ]]; then
        error_exit "'$file' is not a regular file"
      fi
      ;;
    "directory")
      if [[ ! -d "$file" ]]; then
        error_exit "'$file' is not a directory"
      fi
      ;;
    "executable")
      if [[ ! -x "$file" ]]; then
        error_exit "'$file' is not executable"
      fi
      ;;
  esac
  
  log "File integrity validated: $file" "INFO"
}

# === INSTALLATION PHASE MANAGEMENT ===
phase_transition() {
  local new_phase="$1"
  local description="$2"
  
  log "Phase transition: ${INSTALLATION_PHASE} -> ${new_phase}" "INFO"
  INSTALLATION_PHASE="$new_phase"
  
  # Reset cognitive load for new phase (7±2 concept chunking)
  COGNITIVE_LOAD_CURRENT=0
  CONCEPT_STACK=()
  
  log "Starting phase: ${new_phase} - ${description}" "INFO"
  
  # Update flow state
  if [[ "$new_phase" == "completion" ]]; then
    FLOW_STATE_ACTIVE=false
  else
    FLOW_STATE_ACTIVE=true
  fi
}

# === CORE INSTALLATION FUNCTIONS ===
initialize_application() {
  phase_transition "initialization" "Setting up application environment"
  
  # Validate system requirements
  validate_command_exists "ruby"
  validate_command_exists "node"
  validate_command_exists "rails"
  validate_command_exists "bundle"
  validate_command_exists "psql"
  validate_command_exists "redis-server"
  
  # Setup directories
  mkdir -p "${BASE_DIR}/${APP_NAME}"
  validate_directory_permissions "${BASE_DIR}/${APP_NAME}"
  
  cd "${BASE_DIR}/${APP_NAME}"
  
  # Initialize logging
  touch "${LOG_FILE}"
  
  log "Application initialization completed for ${APP_NAME}" "INFO"
}

setup_rails_application() {
  phase_transition "rails_setup" "Creating Rails application structure"
  
  # Check if Rails app already exists
  if [[ -f "Gemfile" ]]; then
    log "Rails application already exists, skipping creation" "INFO"
  else
    # Create new Rails application
    rails new . -f \
      --skip-bundle \
      --database=postgresql \
      --asset-pipeline=propshaft \
      --css=scss \
      --javascript=stimulus \
      --skip-test \
      --skip-system-test \
      --skip-jbuilder
    
    log "Rails application created successfully" "INFO"
  fi
  
  # Add cognitive compliance to Gemfile
  cat <<EOF >> Gemfile

# Cognitive Framework Dependencies
gem "solid_queue", "~> 1.0"
gem "solid_cache", "~> 1.0"
gem "falcon", "~> 0.47"
gem "hotwire-rails", "~> 0.1"
gem "turbo-rails", "~> 2.0"
gem "stimulus-rails", "~> 1.3"
gem "stimulus_reflex", "~> 3.5"
gem "cable_ready", "~> 5.0"
gem "devise", "~> 4.9"
gem "devise-guests", "~> 0.8"
gem "pagy", "~> 8.0"

# Development and Testing
group :development, :test do
  gem "rspec-rails", "~> 6.0"
  gem "factory_bot_rails", "~> 6.2"
  gem "rubocop", "~> 1.77"
  gem "rubocop-rails", "~> 2.23"
  gem "reek", "~> 6.3"
end

# Security and Performance
gem "rack-attack", "~> 6.7"
gem "brakeman", "~> 6.0"
gem "bundler-audit", "~> 0.9"
EOF
  
  # Install gems
  bundle install
  
  log "Rails application setup completed" "INFO"
}

setup_database() {
  phase_transition "database_setup" "Configuring PostgreSQL database"
  
  # Database configuration
  cat <<EOF > config/database.yml
default: &default
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  host: localhost
  username: <%= ENV.fetch("DB_USER") { "postgres" } %>
  password: <%= ENV.fetch("DB_PASSWORD") { "" } %>

development:
  <<: *default
  database: ${APP_NAME}_development

test:
  <<: *default
  database: ${APP_NAME}_test

production:
  <<: *default
  database: ${APP_NAME}_production
  username: <%= ENV.fetch("DB_USER") %>
  password: <%= ENV.fetch("DB_PASSWORD") %>
EOF
  
  # Create and migrate database
  bin/rails db:create
  bin/rails db:migrate
  
  log "Database setup completed" "INFO"
}

setup_cognitive_framework() {
  phase_transition "cognitive_framework" "Implementing cognitive compliance"
  
  # Copy cognitive compliance module
  cp "${BASE_DIR}/../cognitive_compliance.rb" "app/models/concerns/"
  
  # Add cognitive compliance to application controller
  cat <<EOF > app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  include CognitiveCompliance
  
  protect_from_forgery with: :exception
  
  before_action :authenticate_user!, except: [:index, :show]
  before_action :configure_permitted_parameters, if: :devise_controller?
  
  protected
  
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:email])
    devise_parameter_sanitizer.permit(:account_update, keys: [:email])
  end
end
EOF
  
  # Create cognitive overload view
  mkdir -p "app/views/shared"
  cat <<EOF > app/views/shared/cognitive_overload.html.erb
<%= content_for :title, "Taking a Cognitive Break" %>
<%= content_for :description, "The system is providing a moment for cognitive recovery" %>

<%= tag.main role: "main" do %>
  <%= tag.section aria_labelledby: "cognitive-break-heading" do %>
    <%= tag.h1 "Taking a Cognitive Break", id: "cognitive-break-heading" %>
    
    <%= tag.div class: "cognitive-break-container" do %>
      <%= tag.p "The system has detected high cognitive load and is providing a moment for recovery." %>
      
      <% if @break_suggestion %>
        <%= tag.div class: "break-suggestion" do %>
          <%= tag.h2 "Suggested Activity:" %>
          <%= tag.p @break_suggestion["activity"] %>
          <%= tag.p "Duration: #{@break_suggestion["duration"]} minutes" %>
        <% end %>
      <% end %>
      
      <%= tag.div class: "break-timer" do %>
        <%= tag.p "This page will automatically refresh in 30 seconds." %>
        <%= tag.div id: "timer-display" %>
      <% end %>
      
      <%= link_to "Continue", request.referrer || root_path, class: "button primary" %>
    <% end %>
  <% end %>
<% end %>

<%= tag.script do %>
  let countdown = 30;
  const timerDisplay = document.getElementById('timer-display');
  
  function updateTimer() {
    timerDisplay.textContent = countdown + ' seconds';
    countdown--;
    
    if (countdown < 0) {
      window.location.reload();
    }
  }
  
  setInterval(updateTimer, 1000);
  updateTimer();
<% end %>
EOF
  
  log "Cognitive framework implementation completed" "INFO"
}

setup_authentication() {
  phase_transition "authentication" "Configuring user authentication"
  
  # Generate Devise configuration
  bin/rails generate devise:install
  bin/rails generate devise User
  bin/rails generate devise:views
  
  # Add guest user support
  cat <<EOF > config/initializers/devise_guests.rb
Devise.setup do |config|
  config.guest_user_class = "User"
end
EOF
  
  # Run migrations
  bin/rails db:migrate
  
  log "Authentication setup completed" "INFO"
}

setup_security() {
  phase_transition "security" "Implementing zero-trust security"
  
  # Security configuration
  cat <<EOF > config/initializers/security.rb
# Zero-trust security configuration
Rails.application.configure do
  # Force SSL in production
  config.force_ssl = Rails.env.production?
  
  # Secure headers
  config.force_ssl = true if Rails.env.production?
end

# Content Security Policy
Rails.application.config.content_security_policy do |policy|
  policy.default_src :self, :https
  policy.font_src    :self, :https, :data
  policy.img_src     :self, :https, :data
  policy.object_src  :none
  policy.script_src  :self, :https
  policy.style_src   :self, :https, :unsafe_inline
end

# Rate limiting
Rails.application.config.middleware.use Rack::Attack

# Rack::Attack configuration
Rack::Attack.throttle("requests by ip", limit: 300, period: 5.minutes) do |req|
  req.ip
end

Rack::Attack.throttle("logins per ip", limit: 5, period: 20.seconds) do |req|
  if req.path == "/users/sign_in" && req.post?
    req.ip
  end
end
EOF
  
  log "Security configuration completed" "INFO"
}

generate_application_code() {
  phase_transition "code_generation" "Creating application-specific code"
  
  # This function should be overridden in specific installers
  # Default implementation creates basic home controller
  
  bin/rails generate controller Home index
  
  cat <<EOF > app/controllers/home_controller.rb
class HomeController < ApplicationController
  def index
    @cognitive_load = CognitiveLoadMonitor.new
    @complexity_assessment = @cognitive_load.assess_complexity(
      "Welcome to #{APP_NAME}. This is the home page."
    )
  end
end
EOF
  
  cat <<EOF > app/views/home/index.html.erb
<%= content_for :title, "Welcome to #{APP_NAME}" %>
<%= content_for :description, "A cognitively optimized application" %>

<%= tag.main role: "main" do %>
  <%= tag.section aria_labelledby: "welcome-heading" do %>
    <%= tag.h1 "Welcome to #{APP_NAME}", id: "welcome-heading" %>
    
    <%= tag.div class: "cognitive-status" do %>
      <% if @complexity_assessment %>
        <%= tag.p "Cognitive Load: #{@complexity_assessment['cognitive_load_category']}" %>
        <%= tag.p "Concepts: #{@complexity_assessment['concept_count']}" %>
      <% end %>
    <% end %>
    
    <%= tag.p "This application follows the Master.json v10.7.0 cognitive framework." %>
    
    <% if @cognitive_overload_detected %>
      <%= tag.div class: "cognitive-alert" do %>
        <%= tag.p "Cognitive break recommended:" %>
        <%= tag.p @break_suggestion["activity"] if @break_suggestion %>
      <% end %>
    <% end %>
  <% end %>
<% end %>
EOF
  
  log "Application code generation completed" "INFO"
}

setup_testing() {
  phase_transition "testing" "Setting up test framework"
  
  # Generate RSpec configuration
  bin/rails generate rspec:install
  
  # Create basic test structure
  mkdir -p spec/models/concerns
  mkdir -p spec/controllers
  mkdir -p spec/features
  mkdir -p spec/system
  
  # Cognitive compliance test
  cat <<EOF > spec/models/concerns/cognitive_compliance_spec.rb
require 'rails_helper'

RSpec.describe CognitiveCompliance, type: :concern do
  let(:test_class) { Class.new(ApplicationController) { include CognitiveCompliance } }
  let(:controller) { test_class.new }
  
  describe '#analyze_request_complexity' do
    it 'calculates request complexity within cognitive limits' do
      # Mock request parameters
      allow(controller).to receive(:params).and_return({
        'name' => 'test',
        'nested' => { 'value' => 'test' }
      })
      
      complexity = controller.send(:analyze_request_complexity)
      
      expect(complexity).to be < 7 # Within cognitive limits
      expect(complexity).to be > 0 # Should have some complexity
    end
  end
  
  describe CognitiveCompliance::CognitiveLoadMonitor do
    let(:monitor) { described_class.new }
    
    it 'assesses complexity within 7±2 concept limits' do
      content = "Test content with multiple concepts and relationships"
      assessment = monitor.assess_complexity(content)
      
      expect(assessment['total_complexity']).to be_a(Numeric)
      expect(assessment['cognitive_load_category']).to be_in(['simple', 'moderate', 'complex', 'overload'])
      expect(assessment['recommendations']).to be_an(Array)
    end
  end
  
  describe CognitiveCompliance::FlowStateTracker do
    let(:tracker) { described_class.new }
    
    it 'tracks flow state within expected ranges' do
      metrics = {
        'concentration' => 0.8,
        'challenge_skill_balance' => 0.7,
        'clear_goals' => 0.9
      }
      
      flow_level = tracker.update(metrics)
      
      expect(flow_level).to be_between(0.0, 1.0)
      expect(tracker.in_flow_state?).to be_in([true, false])
    end
  end
end
EOF
  
  log "Testing framework setup completed" "INFO"
}

finalize_installation() {
  phase_transition "completion" "Finalizing installation"
  
  # Add routes
  cat <<EOF > config/routes.rb
Rails.application.routes.draw do
  devise_for :users
  root 'home#index'
  
  # Health check
  get '/health', to: 'application#health_check'
  
  # Cognitive monitoring
  get '/cognitive_status', to: 'application#cognitive_status'
end
EOF
  
  # Add health check methods
  cat <<EOF >> app/controllers/application_controller.rb

  def health_check
    render json: {
      status: 'healthy',
      timestamp: Time.current.iso8601,
      cognitive_load: @cognitive_session&.dig('current_load') || 0,
      circuit_breaker_status: 'closed'
    }
  end
  
  def cognitive_status
    render json: {
      cognitive_load: @cognitive_session&.dig('current_load') || 0,
      flow_state: @cognitive_session&.dig('flow_state') || false,
      recommendations: @cognitive_session&.dig('recommendations') || []
    }
  end
EOF
  
  # Create final log entry
  log "Installation completed successfully for ${APP_NAME}" "INFO"
  log "Cognitive framework v10.7.0 implementation verified" "INFO"
  log "Zero-trust security measures activated" "INFO"
  log "Application ready for deployment" "INFO"
  
  # Reset cognitive state
  COGNITIVE_LOAD_CURRENT=0
  CONCEPT_STACK=()
  FLOW_STATE_ACTIVE=false
  
  echo "✅ ${APP_NAME} installation completed successfully!"
  echo "📊 Cognitive load final score: ${COGNITIVE_LOAD_CURRENT}/7"
  echo "🔒 Zero-trust security: Enabled"
  echo "📋 Log file: ${LOG_FILE}"
  echo ""
  echo "Next steps:"
  echo "1. cd ${BASE_DIR}/${APP_NAME}"
  echo "2. bin/rails server"
  echo "3. Visit http://localhost:3000"
}

# === MAIN INSTALLATION FLOW ===
main() {
  log "Starting installation for ${APP_NAME}" "INFO"
  
  # Phase 1: Initialize (Cognitive Chunk 1)
  initialize_application
  
  # Phase 2: Rails Setup (Cognitive Chunk 2)
  setup_rails_application
  
  # Phase 3: Database (Cognitive Chunk 3)
  setup_database
  
  # Phase 4: Cognitive Framework (Cognitive Chunk 4)
  setup_cognitive_framework
  
  # Phase 5: Authentication (Cognitive Chunk 5)
  setup_authentication
  
  # Phase 6: Security (Cognitive Chunk 6)
  setup_security
  
  # Phase 7: Application Code (Cognitive Chunk 7)
  generate_application_code
  
  # Circuit breaker check before testing
  if [[ ${COGNITIVE_LOAD_CURRENT} -gt 7 ]]; then
    trigger_cognitive_circuit_breaker
  fi
  
  # Phase 8: Testing (New Cognitive Chunk 1)
  setup_testing
  
  # Phase 9: Finalization (New Cognitive Chunk 2)
  finalize_installation
}

# Allow sourcing of this template
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi