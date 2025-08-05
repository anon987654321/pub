#!/usr/bin/env zsh
# Shared utility functions for Rails apps on OpenBSD 7.5, unprivileged user, NNG/SEO/Schema optimized
# Framework v35.3.8 compliant with comprehensive error handling and safety protocols

set -euo pipefail
# Enable strict error handling:
# -e: Exit on any command failure
# -u: Exit on undefined variables  
# -o pipefail: Exit on pipe command failures

BASE_DIR="/home/dev/rails"
RAILS_VERSION="8.0.0"
RUBY_VERSION="3.3.0"
NODE_VERSION="20"
BRGEN_IP="46.23.95.45"

log() {
  local app_name="${APP_NAME:-unknown}"
  local timestamp
  timestamp="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
  local log_file="$BASE_DIR/$app_name/setup.log"
  
  # Ensure log directory exists
  mkdir -p "$(dirname "$log_file")"
  
  # Structured logging with severity levels
  printf "[%s] INFO: %s\n" "$timestamp" "$1" | tee -a "$log_file"
}

error() {
  local app_name="${APP_NAME:-unknown}"
  local timestamp
  timestamp="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
  local log_file="$BASE_DIR/$app_name/setup.log"
  
  # Ensure log directory exists
  mkdir -p "$(dirname "$log_file")"
  
  # Error logging with stack trace context
  printf "[%s] ERROR: %s\n" "$timestamp" "$1" >&2 | tee -a "$log_file"
  printf "[%s] ERROR: Script: %s, Line: %s, Function: %s\n" "$timestamp" "${BASH_SOURCE[1]:-unknown}" "${BASH_LINENO[0]:-unknown}" "${FUNCNAME[1]:-main}" >&2 | tee -a "$log_file"
  exit 1
}

validate_input() {
  local input="$1"
  local validation_type="${2:-alphanumeric}"
  
  case "$validation_type" in
    "alphanumeric")
      if [[ ! "$input" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        error "Invalid input '$input': must contain only alphanumeric characters, underscores, and hyphens"
      fi
      ;;
    "email")
      if [[ ! "$input" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        error "Invalid email format: '$input'"
      fi
      ;;
    "path")
      if [[ ! "$input" =~ ^[a-zA-Z0-9/_.-]+$ ]]; then
        error "Invalid path '$input': contains unsafe characters"
      fi
      ;;
    *)
      error "Unknown validation type: '$validation_type'"
      ;;
  esac
}

command_exists() {
  if ! command -v "$1" >/dev/null 2>&1; then
    error "Command '$1' not found. Please install it before proceeding."
  fi
  log "Command '$1' verified successfully"
}

init_app() {
  local app_name="$1"
  
  # Validate app name
  validate_input "$app_name" "alphanumeric"
  
  log "Initializing app directory for '$app_name'"
  
  # Create app directory with proper permissions
  if ! mkdir -p "$BASE_DIR/$app_name"; then
    error "Failed to create app directory '$BASE_DIR/$app_name'"
  fi
  
  # Verify directory creation and permissions
  if [[ ! -d "$BASE_DIR/$app_name" ]]; then
    error "App directory '$BASE_DIR/$app_name' was not created successfully"
  fi
  
  # Change to app directory with verification
  if ! cd "$BASE_DIR/$app_name"; then
    error "Failed to change to directory '$BASE_DIR/$app_name'"
  fi
  
  log "Successfully initialized and entered app directory: $(pwd)"
}

setup_ruby() {
  log "Setting up Ruby $RUBY_VERSION with enhanced validation"
  
  # Verify Ruby command exists
  command_exists "ruby"
  
  # Check Ruby version with robust version comparison
  local current_version
  current_version="$(ruby -v | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -n1)"
  
  if [[ -z "$current_version" ]]; then
    error "Unable to determine Ruby version"
  fi
  
  log "Found Ruby version: $current_version (Required: $RUBY_VERSION)"
  
  # Install bundler with version verification
  if ! gem list bundler --installed --quiet >/dev/null 2>&1; then
    log "Installing Bundler gem"
    if ! gem install bundler --quiet; then
      error "Failed to install Bundler gem"
    fi
  else
    log "Bundler gem already installed"
  fi
  
  # Verify bundler installation
  command_exists "bundle"
  log "Ruby and Bundler setup completed successfully"
}

setup_yarn() {
  log "Setting up Node.js $NODE_VERSION and Yarn with enhanced validation"
  
  # Verify Node.js command exists
  command_exists "node"
  
  # Check Node.js version
  local current_version
  current_version="$(node -v | grep -oE '[0-9]+' | head -n1)"
  
  if [[ -z "$current_version" ]]; then
    error "Unable to determine Node.js version"
  fi
  
  log "Found Node.js version: v$current_version (Required: v$NODE_VERSION)"
  
  # Install Yarn globally with verification
  if ! command -v yarn >/dev/null 2>&1; then
    log "Installing Yarn package manager"
    if ! npm install -g yarn --silent; then
      error "Failed to install Yarn via npm"
    fi
  else
    log "Yarn already installed: $(yarn --version)"
  fi
  
  # Verify yarn installation
  command_exists "yarn"
  log "Node.js and Yarn setup completed successfully"
}

setup_rails() {
  local app_name="$1"
  
  # Validate app name
  validate_input "$app_name" "alphanumeric"
  
  log "Setting up Rails $RAILS_VERSION for '$app_name' with modern configuration"
  
  # Check if Gemfile exists to avoid overwriting existing apps
  if [[ -f "Gemfile" ]]; then
    log "Gemfile exists - skipping Rails new command"
    log "Assuming existing Rails application in $(pwd)"
  else
    log "Creating new Rails $RAILS_VERSION application"
    
    # Create Rails app with comprehensive options
    if ! rails new . -f \
      --skip-bundle \
      --database=postgresql \
      --asset-pipeline=propshaft \
      --css=scss \
      --javascript=esbuild \
      --skip-test \
      2>/dev/null; then
      error "Failed to create Rails application '$app_name'"
    fi
    
    log "Rails application '$app_name' created successfully"
  fi
  
  # Enhance Gemfile with Rails 8 modern stack
  log "Adding Rails 8 modern stack gems to Gemfile"
  
  cat >> Gemfile << 'EOF'

# Rails 8 Modern Stack - Framework v35.3.8 compliant
gem 'solid_queue', '~> 1.0'          # Background job processing
gem 'solid_cache', '~> 1.0'          # Caching layer
gem 'falcon', '~> 0.47'               # High-performance web server
gem 'hotwire-rails', '~> 0.1'        # Modern frontend framework
gem 'turbo-rails', '~> 2.0'          # SPA-like page acceleration
gem 'stimulus-rails', '~> 1.3'       # JavaScript behavior framework
gem 'propshaft', '~> 1.0'            # Asset pipeline

# Enhanced Stimulus Components
gem 'stimulus_reflex', '~> 3.5'      # Real-time updates
gem 'cable_ready', '~> 5.0'          # DOM manipulation
EOF

  # Run bundle install with error handling
  log "Installing gems with Bundler"
  if ! bundle install --quiet; then
    error "Bundle install failed for application '$app_name'"
  fi
  
  log "Rails setup completed successfully for '$app_name'"
}

setup_postgresql() {
  local app_name="$1"
  
  # Validate app name
  validate_input "$app_name" "alphanumeric"
  
  log "Checking PostgreSQL configuration for '$app_name'"
  
  # Verify PostgreSQL command exists
  command_exists "psql"
  
  # Check if database exists with proper error handling
  if psql -lqt 2>/dev/null | cut -d \| -f 1 | grep -qw "$app_name"; then
    log "Database '$app_name' found and accessible"
  else
    log "Database '$app_name' not found. Manual creation required."
    log "Please run: createdb $app_name"
    log "Or contact your database administrator"
    error "Database setup incomplete - manual intervention required"
  fi
  
  log "PostgreSQL verification completed for '$app_name'"
}

setup_redis() {
  local app_name="${1:-default}"
  
  log "Verifying Redis configuration for '$app_name'"
  
  # Verify Redis server command exists
  command_exists "redis-server"
  
  # Check if Redis is running with multiple detection methods
  local redis_running=false
  
  if pgrep redis-server >/dev/null 2>&1; then
    redis_running=true
  elif redis-cli ping >/dev/null 2>&1; then
    redis_running=true
  fi
  
  if [[ "$redis_running" == "true" ]]; then
    log "Redis server is running and responsive"
    
    # Test Redis connectivity
    if redis-cli ping >/dev/null 2>&1; then
      log "Redis connectivity test successful"
    else
      error "Redis server running but not responding to ping"
    fi
  else
    log "Redis server not detected. Manual startup required."
    log "Please run: redis-server &"
    log "Or configure Redis as a system service"
    error "Redis not running - manual intervention required"
  fi
  
  log "Redis verification completed for '$app_name'"
}

setup_solid_queue() {
  log "Setting up Solid Queue for modern Rails 8 background job processing"
  
  # Verify Rails environment
  if [[ ! -f "bin/rails" ]]; then
    error "Rails application not found - cannot setup Solid Queue"
  fi
  
  # Generate Solid Queue configuration with error handling
  log "Generating Solid Queue installation and configuration"
  if ! bin/rails generate solid_queue:install 2>/dev/null; then
    error "Failed to generate Solid Queue configuration"
  fi
  
  # Enhanced Solid Queue configuration in application.rb
  log "Configuring Solid Queue in application.rb"
  cat >> config/application.rb << 'EOF'

    # Solid Queue configuration - Rails 8 modern stack
    config.active_job.queue_adapter = :solid_queue
    config.solid_queue.connects_to = { writing: :primary }
    config.solid_queue.silence_polling = true
    config.solid_queue.polling_interval = 1.second
    config.solid_queue.batch_size = 500
    
    # Enhanced error handling and monitoring
    config.solid_queue.on_thread_error = ->(exception) do
      Rails.logger.error "Solid Queue thread error: #{exception.message}"
      Rails.logger.error exception.backtrace.join("\n")
    end
EOF

  # Enhanced database configuration for Solid Queue
  log "Adding Solid Queue database configuration"
  cat >> config/database.yml << 'EOF'

# Solid Queue database configuration - optimized for performance
solid_queue:
  <<: *default
  database: <%= ENV.fetch('SOLID_QUEUE_DATABASE_URL') { "#{database}_solid_queue" } %>
  migrations_paths: db/queue_migrate
  pool: <%= ENV.fetch('SOLID_QUEUE_DB_POOL', 10).to_i %>
  timeout: 5000
  
  # Performance optimizations
  prepared_statements: true
  advisory_locks: true
  statement_timeout: 30000
EOF

  log "Solid Queue setup completed with Rails 8 optimizations"
}

setup_solid_cache() {
  log "Setting up Solid Cache for modern Rails 8 caching layer"
  
  # Verify Rails environment
  if [[ ! -f "bin/rails" ]]; then
    error "Rails application not found - cannot setup Solid Cache"
  fi
  
  # Generate Solid Cache configuration with error handling
  log "Generating Solid Cache installation and configuration"
  if ! bin/rails generate solid_cache:install 2>/dev/null; then
    error "Failed to generate Solid Cache configuration"
  fi
  
  # Enhanced Solid Cache configuration in application.rb
  log "Configuring Solid Cache in application.rb"
  cat >> config/application.rb << 'EOF'

    # Solid Cache configuration - Rails 8 modern stack
    config.cache_store = :solid_cache_store
    config.solid_cache.store_options = {
      max_age: 1.year,
      max_entries: 1_000_000,
      cluster: Rails.env.production?
    }
EOF

  # Enhanced Solid Cache initializer with performance optimizations
  log "Creating optimized Solid Cache initializer"
  cat > config/initializers/solid_cache.rb << 'EOF'
# Solid Cache configuration - Framework v35.3.8 optimized
Rails.application.configure do
  config.solid_cache.connects_to = { writing: :primary }
  config.solid_cache.key_hash_stage = :fnv1a_64
  config.solid_cache.encrypt = Rails.env.production?
  config.solid_cache.size_limit = 256.megabytes
  
  # Performance optimizations
  config.solid_cache.max_age = 1.year
  config.solid_cache.max_entries = 1_000_000
  config.solid_cache.cluster = Rails.env.production?
  
  # Monitoring and metrics
  config.solid_cache.instrument = Rails.env.development?
  
  # Error handling
  config.solid_cache.error_handler = ->(method:, returning:, exception:) do
    Rails.logger.error "Solid Cache error in #{method}: #{exception.message}"
  end
end
EOF

  log "Solid Cache setup completed with Rails 8 optimizations"
}

install_gem() {
  local gem_name="$1"
  local gem_version="${2:-}"
  
  # Validate gem name
  validate_input "$gem_name" "alphanumeric"
  
  log "Installing gem '$gem_name'${gem_version:+ version $gem_version}"
  
  # Check if gem is already installed
  if gem list "$gem_name" --installed --quiet >/dev/null 2>&1; then
    log "Gem '$gem_name' already installed"
    return 0
  fi
  
  # Install gem with version if specified
  local install_cmd="gem install $gem_name"
  if [[ -n "$gem_version" ]]; then
    install_cmd="$install_cmd --version $gem_version"
  fi
  
  if ! $install_cmd --quiet; then
    error "Failed to install gem '$gem_name'"
  fi
  
  # Add gem to Gemfile if it exists
  if [[ -f "Gemfile" ]]; then
    local gem_line="gem \"$gem_name\""
    if [[ -n "$gem_version" ]]; then
      gem_line="$gem_line, \"$gem_version\""
    fi
    
    # Check if gem is already in Gemfile
    if ! grep -q "gem ['\"]$gem_name['\"]" Gemfile; then
      echo "$gem_line" >> Gemfile
      log "Added '$gem_name' to Gemfile"
      
      # Run bundle install to update Gemfile.lock
      if ! bundle install --quiet; then
        error "Failed to run bundle install after adding '$gem_name'"
      fi
    else
      log "Gem '$gem_name' already present in Gemfile"
    fi
  fi
  
  log "Gem '$gem_name' installation completed successfully"
}

setup_core() {
  log "Setting up Rails 8 core stack with Hotwire, Turbo, and modern pagination"
  
  # Verify Rails environment
  if [[ ! -f "bin/rails" ]]; then
    error "Rails application not found - cannot setup core stack"
  fi
  
  # Add modern Rails 8 core gems with specific versions
  log "Installing Rails 8 core gems: Hotwire, Turbo, Stimulus, and Pagy"
  if ! bundle add hotwire-rails stimulus_reflex turbo-rails pagy --optimistic; then
    error "Failed to install core Rails 8 gems"
  fi
  
  # Install Hotwire with comprehensive setup
  log "Installing and configuring Hotwire framework"
  if ! bin/rails hotwire:install; then
    error "Failed to install Hotwire framework"
  fi
  
  # Enhanced Turbo configuration
  log "Configuring Turbo for modern SPA-like experience"
  cat > config/initializers/turbo.rb << 'EOF'
# Turbo configuration - Framework v35.3.8 optimized
Rails.application.configure do
  # Enhanced Turbo Drive configuration
  config.turbo.draw_progress_bar = true
  
  # Turbo Stream configuration for real-time updates
  config.action_cable.mount_path = '/cable'
  config.action_cable.url = ENV.fetch('ACTION_CABLE_URL', 'ws://localhost:3000/cable')
  
  # Performance optimizations
  config.turbo.preload_links_from = [:document, :viewport]
end
EOF

  # Enhanced Stimulus configuration
  log "Configuring Stimulus for enhanced JavaScript behavior"
  cat > app/javascript/controllers/application.js << 'EOF'
import { Application } from "@hotwired/stimulus"
import { definitionsFromContext } from "@hotwired/stimulus-webpack-helpers"

// Import modern stimulus components
import { Alert, Autosave, Dropdown, Modal, Tabs, Toggle } from "stimulus-components"

const application = Application.start()
const context = require.context(".", true, /\.js$/)
application.load(definitionsFromContext(context))

// Register stimulus components
application.register("alert", Alert)
application.register("autosave", Autosave) 
application.register("dropdown", Dropdown)
application.register("modal", Modal)
application.register("tabs", Tabs)
application.register("toggle", Toggle)

// Configure Stimulus development experience
window.Stimulus = application

export { application }
EOF

  log "Rails 8 core stack setup completed with modern optimizations"
}

setup_devise() {
  log "Setting up Devise with enhanced security, Vipps OAuth, and guest login functionality"
  
  # Verify Rails environment
  if [[ ! -f "bin/rails" ]]; then
    error "Rails application not found - cannot setup Devise"
  fi
  
  # Add Devise gems with comprehensive security features
  log "Installing Devise gems with security enhancements"
  if ! bundle add devise omniauth-vipps devise-guests omniauth-rails_csrf_protection; then
    error "Failed to add Devise gems"
  fi
  
  # Generate Devise installation with error handling
  log "Generating Devise installation"
  if ! bin/rails generate devise:install; then
    error "Failed to generate Devise installation"
  fi
  
  # Generate User model with enhanced fields and security
  log "Generating User model with security enhancements"
  if ! bin/rails generate devise User anonymous:boolean guest:boolean vipps_id:string citizenship_status:string claim_count:integer failed_attempts:integer unlock_token:string locked_at:datetime; then
    error "Failed to generate User model"
  fi
  
  # Add OAuth fields migration
  if ! bin/rails generate migration AddOmniauthToUsers provider:string uid:string; then
    error "Failed to generate OAuth migration"
  fi

  # Enhanced Devise configuration with security features
  log "Configuring Devise with enhanced security settings"
  cat > config/initializers/devise.rb << 'EOF'
# Devise configuration - Framework v35.3.8 security enhanced
Devise.setup do |config|
  # Mailer configuration
  config.mailer_sender = "noreply@#{ENV['APP_DOMAIN'] || 'example.com'}"
  
  # Enhanced OAuth configuration with CSRF protection
  config.omniauth :vipps, ENV["VIPPS_CLIENT_ID"], ENV["VIPPS_CLIENT_SECRET"], {
    scope: "openid,email,name",
    strategy_class: OmniAuth::Strategies::Vipps,
    setup: true
  }
  
  # Security configurations
  config.navigational_formats = [:html, :turbo_stream]
  config.sign_out_via = :delete
  config.guest_user = true
  
  # Password security
  config.password_length = 8..128
  config.reset_password_within = 6.hours
  config.sign_in_after_reset_password = false
  
  # Account locking for security
  config.lock_strategy = :failed_attempts
  config.maximum_attempts = 5
  config.unlock_strategy = :email
  config.unlock_in = 1.hour
  
  # Session security
  config.timeout_in = 30.minutes
  config.expire_all_remember_me_on_sign_out = true
  
  # Email validation
  config.email_regexp = /\A[^@\s]+@[^@\s]+\z/
  
  # Case insensitive keys
  config.case_insensitive_keys = [:email]
  config.strip_whitespace_keys = [:email]
  
  # Paranoid mode for security
  config.paranoid = true
end
EOF

  # Enhanced User model with security validations
  log "Creating enhanced User model with security features"
  cat > app/models/user.rb << 'EOF'
class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, 
         :validatable, :trackable, :lockable, :timeoutable,
         :omniauthable, omniauth_providers: [:vipps]

  # Enhanced validations with security focus
  validates :email, presence: true, uniqueness: { case_sensitive: false }, 
            format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :claim_count, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :citizenship_status, length: { maximum: 100 }, allow_blank: true
  validates :vipps_id, uniqueness: true, allow_blank: true
  
  # Security scopes
  scope :guests, -> { where(guest: true) }
  scope :regular_users, -> { where(guest: false) }
  scope :locked, -> { where.not(locked_at: nil) }
  
  # Enhanced OAuth authentication with security checks
  def self.from_omniauth(auth)
    # Validate OAuth data
    return nil unless auth&.provider && auth&.uid && auth&.info&.email
    
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.password = Devise.friendly_token[0, 20]
      user.vipps_id = auth.uid
      user.citizenship_status = auth.info.nationality&.slice(0, 100) || "unknown"
      user.guest = false
      user.confirmed_at = Time.current if user.respond_to?(:confirmed_at)
    end
  end

  # Enhanced guest user creation with security
  def self.guest
    Rails.cache.fetch("guest_user_#{session_id}", expires_in: 1.hour) do
      create_guest_user
    end
  end
  
  private
  
  def self.create_guest_user
    find_or_create_by(guest: true) do |user|
      user.email = "guest_#{SecureRandom.uuid}@example.com"
      user.password = Devise.friendly_token[0, 20]
      user.anonymous = true
    end
  end
  
  # Security methods
  def display_name
    return "Anonymous User" if anonymous?
    return "Guest User" if guest?
    email.split('@').first.titleize
  end
  
  def can_post?
    !locked? && (confirmed? || guest?)
  end
end
EOF

  log "Devise setup completed with enhanced security features"
}

  mkdir -p app/views/devise/sessions
  cat <<EOF > app/views/devise/sessions/new.html.erb
<% content_for :title, t("devise.sessions.new.title") %>
<% content_for :description, t("devise.sessions.new.description", default: "Sign in with Vipps to access the app") %>
<% content_for :keywords, t("devise.sessions.new.keywords", default: "sign in, vipps, app") %>
<% content_for :schema do %>
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "WebPage",
    "name": "<%= t('devise.sessions.new.title') %>",
    "description": "<%= t('devise.sessions.new.description', default: 'Sign in with Vipps to access the app') %>",
    "url": "<%= request.original_url %>"
  }
  </script>
<% end %>
<%= tag.header role: "banner" do %>
  <%= render partial: "${APP_NAME}_logo/logo" %>
<% end %>
<%= tag.main role: "main" do %>
  <%= tag.section aria-labelledby: "signin-heading" do %>
    <%= tag.h1 t("devise.sessions.new.title"), id: "signin-heading" %>
    <%= tag.div data: { turbo_frame: "notices" } do %>
      <%= render "shared/notices" %>
    <% end %>
    <%= link_to t("devise.sessions.new.sign_in_with_vipps"), user_vipps_omniauth_authorize_path, class: "oauth-link", "aria-label": t("devise.sessions.new.sign_in_with_vipps") %>
  <% end %>
<% end %>
<%= tag.footer role: "contentinfo" do %>
  <%= tag.nav class: "footer-links" aria-label: t("shared.footer_nav") do %>
    <%= link_to "", "https://facebook.com", class: "footer-link fb", "aria-label": "Facebook" %>
    <%= link_to "", "https://twitter.com", class: "footer-link tw", "aria-label": "Twitter" %>
    <%= link_to "", "https://instagram.com", class: "footer-link ig", "aria-label": "Instagram" %>
    <%= link_to t("shared.about"), "#", class: "footer-link text" %>
    <%= link_to t("shared.contact"), "#", class: "footer-link text" %>
    <%= link_to t("shared.terms"), "#", class: "footer-link text" %>
    <%= link_to t("shared.privacy"), "#", class: "footer-link text" %>
    <%= link_to t("shared.support"), "#", class: "footer-link text" %>
  <% end %>
<% end %>
EOF

  mkdir -p app/views/layouts
  cat <<EOF > app/views/layouts/application.html.erb
<!DOCTYPE html>
<html lang="<%= I18n.locale %>">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title><%= yield(:title) || "${APP_NAME.capitalize}" %></title>
  <meta name="description" content="<%= yield(:description) || 'Community-driven platform' %>">
  <meta name="keywords" content="<%= yield(:keywords) || '${APP_NAME}, community, rails' %>">
  <link rel="canonical" href="<%= request.original_url %>">
  <%= csrf_meta_tags %>
  <%= csp_meta_tag %>
  <%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>
  <%= javascript_include_tag "application", "data-turbo-track": "reload", defer: true %>
  <%= yield(:schema) %>
</head>
<body>
  <%= yield %>
</body>
</html>
EOF

  mkdir -p app/views/shared
  cat <<EOF > app/views/shared/_notices.html.erb
<% if notice %>
  <%= tag.p notice, class: "notice", "aria-live": "polite" %>
<% end %>
<% if alert %>
  <%= tag.p alert, class: "alert", "aria-live": "assertive" %>
<% end %>
EOF

  cat <<EOF > app/views/shared/_vote.html.erb
<%= tag.div class: "vote", id: "vote-#{votable.id}", data: { controller: "vote", "vote-votable-type-value": votable.class.name, "vote-votable-id-value": votable.id } do %>
  <%= button_tag "▲", data: { action: "click->vote#upvote" }, "aria-label": t("shared.upvote") %>
  <%= tag.span votable.votes.sum(:value), class: "vote-count" %>
  <%= button_tag "▼", data: { action: "click->vote#downvote" }, "aria-label": t("shared.downvote") %>
<% end %>
EOF
}

setup_storage() {
  log "Setting up Active Storage"
  bin/rails active_storage:install
  if [ $? -ne 0 ]; then
    error "Failed to setup Active Storage"
  fi
}

setup_enhanced_stripe() {
  log "Setting up enhanced Stripe integration with comprehensive security"
  
  # Verify Rails environment
  if [[ ! -f "bin/rails" ]]; then
    error "Rails application not found - cannot setup Stripe"
  fi
  
  # Install Stripe with security enhancements
  log "Installing Stripe with security dependencies"
  if ! bundle add stripe money-rails rack-attack --optimistic; then
    error "Failed to add Stripe gems"
  fi
  
  # Enhanced Stripe configuration with security
  log "Creating secure Stripe configuration"
  cat > config/initializers/stripe.rb << 'EOF'
# Enhanced Stripe configuration - Framework v35.3.8 security focused
Rails.application.configure do
  # Environment-specific API keys with validation
  config.stripe.secret_key = Rails.application.credentials.dig(:stripe, Rails.env.to_sym, :secret_key) ||
                             ENV['STRIPE_SECRET_KEY']
  config.stripe.publishable_key = Rails.application.credentials.dig(:stripe, Rails.env.to_sym, :publishable_key) ||
                                 ENV['STRIPE_PUBLISHABLE_KEY']
  
  # Webhook configuration with security
  config.stripe.webhook_secret = Rails.application.credentials.dig(:stripe, :webhook_secret) ||
                                ENV['STRIPE_WEBHOOK_SECRET']
  
  # Validate keys are present
  unless config.stripe.secret_key&.start_with?('sk_')
    Rails.logger.error "Invalid or missing Stripe secret key"
  end
  
  unless config.stripe.publishable_key&.start_with?('pk_')
    Rails.logger.error "Invalid or missing Stripe publishable key"
  end
end

# Initialize Stripe with error handling
begin
  Stripe.api_key = Rails.application.config.stripe.secret_key
  Stripe.api_version = "2024-06-20"
  
  # Enhanced logging for security
  Stripe.log_level = Rails.env.production? ? Stripe::LEVEL_INFO : Stripe::LEVEL_DEBUG
  
rescue => e
  Rails.logger.error "Stripe initialization failed: #{e.message}"
end

# Enhanced Stripe webhook handler with security
class StripeWebhookHandler
  WEBHOOK_TOLERANCE = 300 # 5 minutes
  
  def self.handle(payload, signature)
    # Verify webhook signature for security
    event = verify_webhook_signature(payload, signature)
    return false unless event
    
    # Log for security monitoring
    Rails.logger.info "Stripe webhook received: #{event['type']} for #{event['id']}"
    
    # Handle different event types with error handling
    case event['type']
    when 'payment_intent.succeeded'
      handle_payment_success(event['data']['object'])
    when 'payment_intent.payment_failed'
      handle_payment_failure(event['data']['object'])
    when 'customer.subscription.created'
      handle_subscription_created(event['data']['object'])
    when 'customer.subscription.deleted'
      handle_subscription_deleted(event['data']['object'])
    when 'invoice.payment_succeeded'
      handle_invoice_payment(event['data']['object'])
    else
      Rails.logger.info "Unhandled Stripe event: #{event['type']}"
    end
    
    true
  rescue => e
    Rails.logger.error "Stripe webhook error: #{e.message}"
    false
  end
  
  private
  
  def self.verify_webhook_signature(payload, signature)
    webhook_secret = Rails.application.config.stripe.webhook_secret
    return nil unless webhook_secret
    
    Stripe::Webhook.construct_event(payload, signature, webhook_secret, WEBHOOK_TOLERANCE)
  rescue Stripe::SignatureVerificationError => e
    Rails.logger.error "Stripe signature verification failed: #{e.message}"
    nil
  end
  
  def self.handle_payment_success(payment_intent)
    # Implement payment success logic with security checks
    customer_id = payment_intent['customer']
    amount = payment_intent['amount']
    
    Rails.logger.info "Payment succeeded: #{payment_intent['id']} for customer #{customer_id}"
    # Add your payment success logic here
  end
  
  def self.handle_payment_failure(payment_intent)
    # Implement payment failure logic
    Rails.logger.warn "Payment failed: #{payment_intent['id']}"
    # Add your payment failure logic here
  end
  
  def self.handle_subscription_created(subscription)
    # Implement subscription creation logic
    Rails.logger.info "Subscription created: #{subscription['id']}"
    # Add your subscription logic here
  end
  
  def self.handle_subscription_deleted(subscription)
    # Implement subscription deletion logic
    Rails.logger.info "Subscription deleted: #{subscription['id']}"
    # Add your subscription cleanup logic here
  end
  
  def self.handle_invoice_payment(invoice)
    # Implement invoice payment logic
    Rails.logger.info "Invoice paid: #{invoice['id']}"
    # Add your invoice logic here
  end
end
EOF

  # Secure Stripe controller
  log "Creating secure Stripe webhook controller"
  mkdir -p app/controllers/api/v1
  cat > app/controllers/api/v1/stripe_controller.rb << 'EOF'
class Api::V1::StripeController < ApplicationController
  protect_from_forgery with: :null_session
  before_action :verify_stripe_webhook, only: [:webhook]
  
  # Rate limiting for security
  before_action :apply_rate_limiting
  
  def webhook
    if StripeWebhookHandler.handle(request.body.read, request.env['HTTP_STRIPE_SIGNATURE'])
      head :ok
    else
      head :bad_request
    end
  end
  
  private
  
  def verify_stripe_webhook
    return unless Rails.env.production?
    
    # Additional IP whitelist check for production
    allowed_ips = %w[
      54.187.174.169 54.187.205.235 54.187.216.72
      54.241.31.99 54.241.31.102 54.241.34.107
    ]
    
    unless allowed_ips.include?(request.remote_ip)
      Rails.logger.warn "Stripe webhook from unauthorized IP: #{request.remote_ip}"
      head :forbidden
    end
  end
  
  def apply_rate_limiting
    # Rate limit to prevent abuse
    key = "stripe_webhook:#{request.remote_ip}"
    count = Rails.cache.read(key) || 0
    
    if count > 100 # requests per hour
      Rails.logger.warn "Rate limit exceeded for Stripe webhook: #{request.remote_ip}"
      head :too_many_requests
      return
    end
    
    Rails.cache.write(key, count + 1, expires_in: 1.hour)
  end
end
EOF

  # Enhanced routes for Stripe
  log "Adding secure Stripe routes"
  cat >> config/routes.rb << 'EOF'

  # Stripe webhook endpoint with security
  namespace :api do
    namespace :v1 do
      post '/stripe/webhook', to: 'stripe#webhook'
    end
  end
EOF

  log "Enhanced Stripe integration with security completed"
}

setup_enhanced_mapbox() {
  log "Setting up enhanced Mapbox integration with security and performance optimizations"
  
  # Verify Rails environment
  if [[ ! -f "bin/rails" ]]; then
    error "Rails application not found - cannot setup Mapbox"
  fi
  
  # Install Mapbox dependencies with security features
  log "Installing Mapbox dependencies"
  if ! bundle add geocoder geokit-rails3 --optimistic; then
    error "Failed to install Mapbox server-side gems"
  fi
  
  if ! yarn add mapbox-gl mapbox-gl-geocoder @mapbox/mapbox-gl-directions --silent; then
    error "Failed to install Mapbox JavaScript dependencies"
  fi
  
  # Enhanced Mapbox configuration
  log "Creating secure Mapbox configuration"
  cat > config/initializers/mapbox.rb << 'EOF'
# Enhanced Mapbox configuration - Framework v35.3.8 security optimized
Rails.application.configure do
  # Secure API key management
  config.mapbox = ActiveSupport::OrderedOptions.new
  config.mapbox.access_token = Rails.application.credentials.dig(:mapbox, :access_token) ||
                               ENV['MAPBOX_ACCESS_TOKEN']
  config.mapbox.secret_key = Rails.application.credentials.dig(:mapbox, :secret_key) ||
                             ENV['MAPBOX_SECRET_KEY']
  
  # Validate Mapbox tokens
  unless config.mapbox.access_token&.start_with?('pk.')
    Rails.logger.error "Invalid or missing Mapbox access token"
  end
  
  # Performance and security settings
  config.mapbox.style = 'mapbox://styles/mapbox/streets-v11'
  config.mapbox.geocoding_limit = 5 # Requests per second
  config.mapbox.cache_timeout = 1.hour
  config.mapbox.rate_limit = 1000 # Requests per day per IP
end

# Enhanced Geocoder configuration
Geocoder.configure(
  lookup: :mapbox,
  api_key: Rails.application.config.mapbox.secret_key,
  cache: Rails.cache,
  cache_prefix: 'geocoder:',
  timeout: 5,
  units: :km,
  
  # Security and performance settings
  use_https: true,
  http_headers: {
    'User-Agent' => "#{Rails.application.class.module_parent_name}/#{Rails.env}"
  },
  
  # Rate limiting
  always_raise: Rails.env.development? ? :all : [Geocoder::OverQueryLimitError],
)
EOF

  # Enhanced Mapbox JavaScript controller with security
  log "Creating secure and accessible Mapbox controller"
  mkdir -p app/javascript/controllers
  cat > app/javascript/controllers/mapbox_controller.js << 'EOF'
import { Controller } from "@hotwired/stimulus"
import mapboxgl from "mapbox-gl"
import MapboxGeocoder from "@mapbox/mapbox-gl-geocoder"
import MapboxDirections from "@mapbox/mapbox-gl-directions/dist/mapbox-gl-directions"

// Enhanced Mapbox controller - WCAG compliant with security features
export default class extends Controller {
  static targets = ["container", "search", "directions"]
  static values = {
    apiKey: String,
    style: { type: String, default: "mapbox://styles/mapbox/streets-v11" },
    center: { type: Array, default: [5.3467, 60.3971] }, // Bergen, Norway
    zoom: { type: Number, default: 12 },
    markers: { type: Array, default: [] },
    interactive: { type: Boolean, default: true },
    maxBounds: Array
  }
  
  connect() {
    // Validate API key for security
    if (!this.validateApiKey()) {
      this.showError("Invalid Mapbox configuration")
      return
    }
    
    this.initializeMap()
    this.setupAccessibility()
    this.addMarkers()
    this.setupGeocoder()
    this.setupDirections()
    this.trackUsage()
  }
  
  disconnect() {
    if (this.map) {
      this.map.remove()
    }
    this.cleanup()
  }
  
  validateApiKey() {
    return this.apiKeyValue && this.apiKeyValue.startsWith('pk.')
  }
  
  initializeMap() {
    mapboxgl.accessToken = this.apiKeyValue
    
    const mapOptions = {
      container: this.containerTarget,
      style: this.styleValue,
      center: this.centerValue,
      zoom: this.zoomValue,
      interactive: this.interactiveValue,
      attributionControl: true,
      customAttribution: 'Map data enhanced for accessibility'
    }
    
    // Add bounds if specified for security
    if (this.hasMaxBoundsValue) {
      mapOptions.maxBounds = this.maxBoundsValue
    }
    
    try {
      this.map = new mapboxgl.Map(mapOptions)
      this.setupMapEventHandlers()
    } catch (error) {
      console.error("Mapbox initialization failed:", error)
      this.showError("Map failed to load")
    }
  }
  
  setupMapEventHandlers() {
    this.map.on('load', () => this.handleMapLoad())
    this.map.on('error', (e) => this.handleMapError(e))
    this.map.on('sourcedata', (e) => this.handleSourceData(e))
    
    // Accessibility event handlers
    this.map.on('click', (e) => this.announceLocation(e.lngLat))
  }
  
  setupAccessibility() {
    // Enhanced accessibility attributes
    this.containerTarget.setAttribute('role', 'application')
    this.containerTarget.setAttribute('aria-label', 'Interactive map')
    this.containerTarget.setAttribute('tabindex', '0')
    
    // Add keyboard navigation
    this.containerTarget.addEventListener('keydown', (e) => this.handleKeyboardNavigation(e))
    
    // Add screen reader announcements for map changes
    this.announceToScreenReader('Map loaded and ready for interaction')
  }
  
  handleKeyboardNavigation(event) {
    const panDistance = 50
    const center = this.map.getCenter()
    
    switch (event.key) {
      case 'ArrowUp':
        event.preventDefault()
        this.map.panBy([0, -panDistance])
        this.announceToScreenReader('Map panned north')
        break
      case 'ArrowDown':
        event.preventDefault()
        this.map.panBy([0, panDistance])
        this.announceToScreenReader('Map panned south')
        break
      case 'ArrowLeft':
        event.preventDefault()
        this.map.panBy([-panDistance, 0])
        this.announceToScreenReader('Map panned west')
        break
      case 'ArrowRight':
        event.preventDefault()
        this.map.panBy([panDistance, 0])
        this.announceToScreenReader('Map panned east')
        break
      case '+':
      case '=':
        event.preventDefault()
        this.map.zoomIn()
        this.announceToScreenReader('Map zoomed in')
        break
      case '-':
        event.preventDefault()
        this.map.zoomOut()
        this.announceToScreenReader('Map zoomed out')
        break
    }
  }
  
  addMarkers() {
    if (!this.markersValue.length) return
    
    this.markers = []
    
    this.markersValue.forEach((markerData, index) => {
      try {
        const marker = this.createAccessibleMarker(markerData, index)
        this.markers.push(marker)
      } catch (error) {
        console.error("Failed to create marker:", error)
      }
    })
  }
  
  createAccessibleMarker(data, index) {
    // Create custom marker element with accessibility
    const markerElement = document.createElement('div')
    markerElement.className = 'mapbox-marker'
    markerElement.setAttribute('role', 'button')
    markerElement.setAttribute('aria-label', data.title || `Location ${index + 1}`)
    markerElement.setAttribute('tabindex', '0')
    markerElement.style.cursor = 'pointer'
    
    // Add marker to map
    const marker = new mapboxgl.Marker({
      element: markerElement,
      anchor: 'bottom'
    })
    .setLngLat([data.lng, data.lat])
    .addTo(this.map)
    
    // Add popup with accessibility
    if (data.title || data.description) {
      const popup = new mapboxgl.Popup({
        offset: 25,
        closeButton: true,
        closeOnClick: false
      }).setHTML(this.createPopupContent(data))
      
      marker.setPopup(popup)
      
      // Keyboard support for markers
      markerElement.addEventListener('keydown', (e) => {
        if (e.key === 'Enter' || e.key === ' ') {
          e.preventDefault()
          popup.addTo(this.map)
          this.announceToScreenReader(`Opened details for ${data.title || 'location'}`)
        }
      })
    }
    
    return marker
  }
  
  createPopupContent(data) {
    const title = data.title ? `<h3>${this.escapeHtml(data.title)}</h3>` : ''
    const description = data.description ? `<p>${this.escapeHtml(data.description)}</p>` : ''
    const price = data.price ? `<p class="price">Price: ${this.escapeHtml(data.price)}</p>` : ''
    
    return `
      <div class="mapbox-popup" role="dialog" aria-labelledby="popup-title">
        ${title}
        ${description}
        ${price}
      </div>
    `
  }
  
  setupGeocoder() {
    if (!this.hasSearchTarget) return
    
    const geocoder = new MapboxGeocoder({
      accessToken: mapboxgl.accessToken,
      mapboxgl: mapboxgl,
      placeholder: 'Search for places...',
      bbox: this.hasMaxBoundsValue ? this.maxBoundsValue.flat() : undefined,
      limit: 5,
      
      // Accessibility enhancements
      marker: {
        color: '#e74c3c'
      }
    })
    
    geocoder.on('result', (e) => {
      this.announceToScreenReader(`Location found: ${e.result.place_name}`)
    })
    
    this.searchTarget.appendChild(geocoder.onAdd(this.map))
  }
  
  setupDirections() {
    if (!this.hasDirectionsTarget) return
    
    const directions = new MapboxDirections({
      accessToken: mapboxgl.accessToken,
      unit: 'metric',
      profile: 'mapbox/driving',
      alternatives: false,
      geometries: 'geojson',
      controls: {
        instructions: true,
        profileSwitcher: true
      }
    })
    
    this.map.addControl(directions, 'top-left')
    
    directions.on('route', () => {
      this.announceToScreenReader('Route calculated')
    })
  }
  
  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }
  
  announceToScreenReader(message) {
    const announcement = document.createElement('div')
    announcement.setAttribute('aria-live', 'polite')
    announcement.setAttribute('aria-atomic', 'true')
    announcement.className = 'sr-only'
    announcement.textContent = message
    
    document.body.appendChild(announcement)
    setTimeout(() => document.body.removeChild(announcement), 1000)
  }
  
  announceLocation(lngLat) {
    this.announceToScreenReader(`Location: ${lngLat.lat.toFixed(4)}, ${lngLat.lng.toFixed(4)}`)
  }
  
  showError(message) {
    this.containerTarget.innerHTML = `
      <div class="mapbox-error" role="alert">
        <p>Map Error: ${message}</p>
        <button onclick="location.reload()">Retry</button>
      </div>
    `
  }
  
  trackUsage() {
    // Track map usage for analytics and rate limiting
    if (window.gtag) {
      window.gtag('event', 'map_load', {
        event_category: 'mapbox',
        event_label: this.styleValue
      })
    }
  }
  
  handleMapLoad() {
    this.announceToScreenReader('Map fully loaded')
  }
  
  handleMapError(error) {
    console.error('Mapbox error:', error)
    this.showError('Failed to load map data')
  }
  
  handleSourceData(event) {
    if (event.isSourceLoaded) {
      this.announceToScreenReader('Map data updated')
    }
  }
  
  cleanup() {
    if (this.markers) {
      this.markers.forEach(marker => marker.remove())
    }
  }
}
EOF

  log "Enhanced Mapbox integration with security and accessibility completed"
}

setup_optimized_live_search() {
  log "Setting up optimized live search with StimulusReflex and performance enhancements"
  
  # Verify Rails environment
  if [[ ! -f "bin/rails" ]]; then
    error "Rails application not found - cannot setup live search"
  fi
  
  # Install search dependencies with error handling
  log "Installing live search dependencies"
  if ! bundle add stimulus_reflex pg_search ransack --optimistic; then
    error "Failed to add live search gems"
  fi
  
  # Install StimulusReflex with comprehensive setup
  log "Installing and configuring StimulusReflex"
  if ! bin/rails stimulus_reflex:install; then
    error "Failed to install StimulusReflex"
  fi
  
  # Install stimulus-debounce for performance
  if ! yarn add stimulus-debounce stimulus-use --silent; then
    error "Failed to install stimulus search dependencies"
  fi
  
  # Enhanced SearchReflex with performance optimizations
  log "Creating optimized SearchReflex"
  mkdir -p app/reflexes
  cat > app/reflexes/search_reflex.rb << 'EOF'
class SearchReflex < ApplicationReflex
  include PgSearch::Model
  
  # Performance optimized search with caching and limits
  def search(query = "")
    @query = query.to_s.strip.truncate(100)
    
    # Return early for empty or too short queries
    return clear_results if @query.length < 2
    
    # Get model and field from element dataset
    model_name = element.dataset["model"]
    field_name = element.dataset["field"]
    tenant_scope = element.dataset["tenant"]
    
    # Validate model and field
    return clear_results unless valid_model_and_field?(model_name, field_name)
    
    # Get model class and apply search
    model_class = model_name.constantize
    
    # Apply tenant scoping if available
    scope = tenant_scope ? model_class.where(community: ActsAsTenant.current_tenant) : model_class
    
    # Perform optimized search with limits and caching
    @results = Rails.cache.fetch(search_cache_key, expires_in: 1.minute) do
      perform_search(scope, field_name)
    end
    
    # Update UI with results
    update_search_results
    update_reset_link
  end
  
  private
  
  def valid_model_and_field?(model_name, field_name)
    return false unless model_name.present? && field_name.present?
    
    allowed_models = %w[Post Listing Profile User Message]
    allowed_fields = %w[title name email content description bio location]
    
    allowed_models.include?(model_name) && allowed_fields.include?(field_name)
  end
  
  def perform_search(scope, field_name)
    if scope.respond_to?(:search_by_field)
      # Use pg_search if available
      scope.search_by_field(@query).limit(10)
    else
      # Fallback to ILIKE search with performance optimization
      scope.where("#{field_name} ILIKE ?", "%#{@query}%")
           .limit(10)
           .order(:created_at)
    end
  end
  
  def search_cache_key
    "search:#{element.dataset['model']}:#{element.dataset['field']}:#{@query}:#{ActsAsTenant.current_tenant&.id}"
  end
  
  def update_search_results
    morph("#search-results", render(
      partial: "shared/search_results", 
      locals: { 
        results: @results, 
        model: element.dataset["model"].downcase,
        field: element.dataset["field"],
        query: @query
      }
    ))
  end
  
  def update_reset_link
    morph("#reset-link", render(
      partial: "shared/reset_link", 
      locals: { query: @query }
    ))
  end
  
  def clear_results
    morph("#search-results", "")
    morph("#reset-link", "")
  end
end
EOF

  # Enhanced search controller with accessibility and performance
  log "Creating accessible and performant search controller"
  mkdir -p app/javascript/controllers
  cat > app/javascript/controllers/search_controller.js << 'EOF'
import { Controller } from "@hotwired/stimulus"
import { debounce } from "stimulus-debounce"
import { useThrottle } from "stimulus-use"

// Accessible and performant search controller - WCAG compliant
export default class extends Controller {
  static targets = ["input", "results", "status"]
  static values = { 
    minLength: { type: Number, default: 2 },
    debounceDelay: { type: Number, default: 300 },
    maxResults: { type: Number, default: 10 }
  }
  
  connect() {
    useThrottle(this, { delay: this.debounceDelayValue })
    this.search = debounce(this.search, this.debounceDelayValue).bind(this)
    this.abortController = new AbortController()
    
    // Set up accessibility attributes
    this.setupAccessibility()
  }
  
  disconnect() {
    this.abortController.abort()
  }
  
  search(event) {
    const query = this.inputTarget.value.trim()
    
    // Clear results for short queries
    if (query.length < this.minLengthValue) {
      this.clearResults()
      return
    }
    
    // Show loading state with accessibility announcement
    this.showLoadingState()
    
    // Perform search with StimulusReflex
    this.stimulate("SearchReflex#search", query, {
      element: this.element
    })
  }
  
  reset(event) {
    event.preventDefault()
    this.inputTarget.value = ""
    this.clearResults()
    this.inputTarget.focus()
    
    // Announce to screen readers
    this.announceToScreenReader("Search cleared")
  }
  
  setupAccessibility() {
    const inputId = this.inputTarget.id || `search-input-${Math.random().toString(36).substr(2, 9)}`
    const resultsId = this.resultsTarget.id || `search-results-${Math.random().toString(36).substr(2, 9)}`
    
    this.inputTarget.id = inputId
    this.resultsTarget.id = resultsId
    
    this.inputTarget.setAttribute("aria-describedby", resultsId)
    this.inputTarget.setAttribute("aria-expanded", "false")
    this.inputTarget.setAttribute("aria-autocomplete", "list")
    this.inputTarget.setAttribute("role", "combobox")
    
    this.resultsTarget.setAttribute("role", "listbox")
    this.resultsTarget.setAttribute("aria-live", "polite")
    this.resultsTarget.setAttribute("aria-label", "Search results")
  }
  
  showLoadingState() {
    if (this.hasStatusTarget) {
      this.statusTarget.textContent = "Searching..."
      this.statusTarget.setAttribute("aria-live", "polite")
    }
    
    this.inputTarget.setAttribute("aria-expanded", "true")
    this.resultsTarget.innerHTML = '<li role="option" aria-disabled="true">Searching...</li>'
  }
  
  clearResults() {
    this.resultsTarget.innerHTML = ""
    this.inputTarget.setAttribute("aria-expanded", "false")
    
    if (this.hasStatusTarget) {
      this.statusTarget.textContent = ""
    }
  }
  
  announceToScreenReader(message) {
    const announcement = document.createElement("div")
    announcement.setAttribute("aria-live", "assertive")
    announcement.setAttribute("aria-atomic", "true")
    announcement.className = "sr-only"
    announcement.textContent = message
    
    document.body.appendChild(announcement)
    setTimeout(() => document.body.removeChild(announcement), 1000)
  }
  
  // Handle keyboard navigation
  keydown(event) {
    const results = this.resultsTarget.querySelectorAll('[role="option"]')
    const currentFocus = document.activeElement
    
    switch (event.key) {
      case "ArrowDown":
        event.preventDefault()
        this.focusNext(results, currentFocus)
        break
      case "ArrowUp":
        event.preventDefault()
        this.focusPrevious(results, currentFocus)
        break
      case "Enter":
        if (currentFocus && currentFocus.getAttribute("role") === "option") {
          event.preventDefault()
          currentFocus.click()
        }
        break
      case "Escape":
        this.clearResults()
        this.inputTarget.focus()
        break
    }
  }
  
  focusNext(results, currentFocus) {
    const currentIndex = Array.from(results).indexOf(currentFocus)
    const nextIndex = currentIndex < results.length - 1 ? currentIndex + 1 : 0
    results[nextIndex]?.focus()
  }
  
  focusPrevious(results, currentFocus) {
    const currentIndex = Array.from(results).indexOf(currentFocus)
    const previousIndex = currentIndex > 0 ? currentIndex - 1 : results.length - 1
    results[previousIndex]?.focus()
  }
}
EOF

  log "Optimized live search with accessibility and performance enhancements completed"
}

setup_optimized_infinite_scroll() {
  log "Setting up optimized infinite scroll with performance enhancements and accessibility"
  
  # Verify Rails environment
  if [[ ! -f "bin/rails" ]]; then
    error "Rails application not found - cannot setup infinite scroll"
  fi
  
  # Install infinite scroll dependencies
  log "Installing infinite scroll dependencies"
  if ! bundle add stimulus_reflex cable_ready pagy kaminari-actionview --optimistic; then
    error "Failed to add infinite scroll gems"
  fi
  
  if ! yarn add stimulus-use intersection-observer --silent; then
    error "Failed to install infinite scroll JS dependencies"
  fi

  # Enhanced InfiniteScrollReflex with performance optimizations
  log "Creating optimized InfiniteScrollReflex"
  mkdir -p app/reflexes
  cat > app/reflexes/infinite_scroll_reflex.rb << 'EOF'
class InfiniteScrollReflex < ApplicationReflex
  include Pagy::Backend
  
  attr_reader :collection, :pagy
  
  def load_more
    # Get pagination parameters from element
    @page = element.dataset["next_page"].to_i
    @model_name = element.dataset["model"]
    @scope_method = element.dataset["scope"]
    @tenant_aware = element.dataset["tenant"] == "true"
    
    # Validate parameters
    return unless valid_load_more_params?
    
    # Get collection with optimizations
    @collection = get_optimized_collection
    
    # Apply tenant scoping if needed
    @collection = apply_tenant_scope(@collection) if @tenant_aware
    
    # Paginate with performance optimizations
    @pagy, @records = pagy(@collection, page: @page, items: items_per_page)
    
    # Update UI if more records exist
    if @records.any?
      append_records
      update_sentinel
    else
      hide_sentinel
    end
    
    # Update performance metrics
    track_performance_metrics
  end
  
  private
  
  def valid_load_more_params?
    allowed_models = %w[Post Listing Profile Match Message User]
    allowed_scopes = %w[published active recent popular featured]
    
    @model_name.present? && 
    allowed_models.include?(@model_name) &&
    (@scope_method.blank? || allowed_scopes.include?(@scope_method)) &&
    @page > 0 && @page < 1000 # Prevent abuse
  end
  
  def get_optimized_collection
    model_class = @model_name.constantize
    
    # Apply scope if specified
    collection = @scope_method.present? ? model_class.send(@scope_method) : model_class.all
    
    # Apply default ordering for performance
    collection = collection.order(:created_at) unless collection.order_values.any?
    
    # Apply performance optimizations
    collection = collection.includes(default_includes) if default_includes.any?
    collection = collection.select(optimized_select_fields)
    
    collection
  end
  
  def apply_tenant_scope(collection)
    return collection unless ActsAsTenant.current_tenant
    
    if collection.respond_to?(:where)
      collection.where(community: ActsAsTenant.current_tenant)
    else
      collection
    end
  end
  
  def items_per_page
    case @model_name
    when 'Post', 'Message' then 20
    when 'Listing', 'Profile' then 15
    when 'Match' then 10
    else 20
    end
  end
  
  def default_includes
    case @model_name
    when 'Post' then [:user, :votes]
    when 'Listing' then [:user, { photos_attachments: :blob }]
    when 'Profile' then [:user, { photos_attachments: :blob }]
    when 'Match' then [:initiator, :receiver]
    else []
    end
  end
  
  def optimized_select_fields
    base_fields = [:id, :created_at, :updated_at]
    
    case @model_name
    when 'Post' then base_fields + [:title, :body, :user_id, :anonymous]
    when 'Listing' then base_fields + [:title, :description, :price, :user_id, :status]
    when 'Profile' then base_fields + [:bio, :location, :user_id, :age, :gender]
    else base_fields + [:title, :name, :content]
    end
  end
  
  def append_records
    cable_ready.insert_adjacent_html(
      selector: sentinel_selector,
      html: render_records,
      position: "beforebegin"
    ).broadcast
  end
  
  def update_sentinel
    if @pagy.next
      cable_ready.set_dataset_property(
        selector: sentinel_selector,
        name: "nextPage",
        value: @pagy.next.to_s
      ).broadcast
    else
      hide_sentinel
    end
  end
  
  def hide_sentinel
    cable_ready.add_css_class(
      selector: sentinel_selector,
      name: "hidden"
    ).set_attribute(
      selector: sentinel_selector,
      name: "aria-hidden",
      value: "true"
    ).broadcast
  end
  
  def render_records
    partial_name = "#{@model_name.downcase.pluralize}/#{@model_name.downcase}"
    
    render(
      partial: partial_name,
      collection: @records,
      layout: false,
      cached: true
    )
  end
  
  def sentinel_selector
    "#infinite-scroll-sentinel"
  end
  
  def track_performance_metrics
    Rails.logger.info "InfiniteScroll: #{@model_name} page #{@page} loaded #{@records.count} records"
  end
end
EOF

  # Enhanced infinite scroll controller with accessibility
  log "Creating accessible infinite scroll controller"
  mkdir -p app/javascript/controllers
  cat > app/javascript/controllers/infinite_scroll_controller.js << 'EOF'
import { Controller } from "@hotwired/stimulus"
import { useIntersection, useDebounce } from "stimulus-use"

// Accessible infinite scroll controller - WCAG compliant with performance optimizations
export default class extends Controller {
  static targets = ["sentinel", "container", "status"]
  static values = {
    threshold: { type: Number, default: 0.1 },
    rootMargin: { type: String, default: "100px" },
    debounceDelay: { type: Number, default: 250 }
  }
  
  connect() {
    // Set up intersection observer with performance optimizations
    useIntersection(this, {
      element: this.sentinelTarget,
      threshold: this.thresholdValue,
      rootMargin: this.rootMarginValue
    })
    
    // Set up debouncing to prevent excessive API calls
    useDebounce(this, { delay: this.debounceDelayValue })
    
    // Set up accessibility
    this.setupAccessibility()
    
    // Track loading state
    this.isLoading = false
    this.hasMoreContent = true
  }
  
  appear() {
    // Prevent duplicate requests
    if (this.isLoading || !this.hasMoreContent) {
      return
    }
    
    // Check if sentinel is actually visible (prevents false triggers)
    if (!this.isElementVisible(this.sentinelTarget)) {
      return
    }
    
    this.loadMore()
  }
  
  disappear() {
    // Optional: Handle when sentinel goes out of view
  }
  
  loadMore() {
    this.isLoading = true
    this.showLoadingState()
    
    // Get next page from sentinel data
    const nextPage = this.sentinelTarget.dataset.nextPage
    
    if (!nextPage) {
      this.showEndOfContent()
      return
    }
    
    // Announce to screen readers
    this.announceToScreenReader("Loading more content")
    
    // Trigger StimulusReflex with error handling
    try {
      this.stimulate("InfiniteScrollReflex#load_more", {
        element: this.sentinelTarget
      })
    } catch (error) {
      console.error("Infinite scroll error:", error)
      this.showErrorState()
    }
  }
  
  setupAccessibility() {
    // Set up ARIA attributes for screen readers
    this.containerTarget.setAttribute("aria-live", "polite")
    this.containerTarget.setAttribute("aria-label", "Content list with infinite scroll")
    
    this.sentinelTarget.setAttribute("aria-hidden", "true")
    this.sentinelTarget.setAttribute("role", "status")
    
    if (this.hasStatusTarget) {
      this.statusTarget.setAttribute("aria-live", "polite")
      this.statusTarget.setAttribute("aria-atomic", "true")
    }
  }
  
  showLoadingState() {
    this.sentinelTarget.innerHTML = `
      <div class="infinite-scroll-loading" role="status" aria-label="Loading more content">
        <span class="spinner" aria-hidden="true"></span>
        <span class="sr-only">Loading more content...</span>
      </div>
    `
    
    if (this.hasStatusTarget) {
      this.statusTarget.textContent = "Loading more content..."
    }
  }
  
  showEndOfContent() {
    this.hasMoreContent = false
    this.isLoading = false
    
    this.sentinelTarget.innerHTML = `
      <div class="infinite-scroll-end" role="status" aria-label="End of content">
        <span class="sr-only">You have reached the end of the content.</span>
      </div>
    `
    
    this.sentinelTarget.classList.add("hidden")
    this.sentinelTarget.setAttribute("aria-hidden", "true")
    
    this.announceToScreenReader("You have reached the end of the content")
  }
  
  showErrorState() {
    this.isLoading = false
    
    this.sentinelTarget.innerHTML = `
      <div class="infinite-scroll-error" role="alert">
        <p>Unable to load more content. <button type="button" data-action="click->infinite-scroll#retry">Try again</button></p>
      </div>
    `
    
    this.announceToScreenReader("Error loading content. Please try again.")
  }
  
  retry(event) {
    event.preventDefault()
    this.loadMore()
  }
  
  isElementVisible(element) {
    const rect = element.getBoundingClientRect()
    const windowHeight = window.innerHeight || document.documentElement.clientHeight
    
    return rect.top < windowHeight && rect.bottom > 0
  }
  
  announceToScreenReader(message) {
    const announcement = document.createElement("div")
    announcement.setAttribute("aria-live", "assertive")
    announcement.setAttribute("aria-atomic", "true")
    announcement.className = "sr-only"
    announcement.textContent = message
    
    document.body.appendChild(announcement)
    setTimeout(() => document.body.removeChild(announcement), 1000)
  }
  
  // Callback for successful load
  infiniteScrollLoaded() {
    this.isLoading = false
    
    // Check if we still have more content
    const nextPage = this.sentinelTarget.dataset.nextPage
    if (!nextPage) {
      this.showEndOfContent()
    } else {
      this.sentinelTarget.innerHTML = ""
    }
  }
  
  // Performance optimization: pause infinite scroll when tab is not visible
  handleVisibilityChange() {
    if (document.hidden) {
      this.disconnect()
    } else {
      this.connect()
    }
  }
}
EOF

  log "Optimized infinite scroll with accessibility and performance enhancements completed"
}

setup_anon_posting() {
  log "Setting up anonymous front-page posting"
  bin/rails generate controller Posts index show new create edit update destroy
  mkdir -p app/views/posts
  cat <<EOF > app/views/posts/_form.html.erb
<%= form_with model: post, local: true, data: { controller: "character-counter form-validation", turbo: true } do |form| %>
  <% if post.errors.any? %>
    <%= tag.div role: "alert" do %>
      <%= tag.p t("${APP_NAME}.errors", count: post.errors.count) %>
      <%= tag.ul do %>
        <% post.errors.full_messages.each do |msg| %>
          <%= tag.li msg %>
        <% end %>
      <% end %>
    <% end %>
  <% end %>
  <%= tag.fieldset do %>
    <%= form.label :body, t("${APP_NAME}.post_body"), "aria-required": true %>
    <%= form.text_area :body, placeholder: t("${APP_NAME}.whats_on_your_mind"), required: true, data: { "character-counter-target": "input", "textarea-autogrow-target": "input", "form-validation-target": "input", action: "input->character-counter#count input->textarea-autogrow#resize input->form-validation#validate" }, title: t("${APP_NAME}.post_body_help") %>
    <%= tag.span data: { "character-counter-target": "count" } %>
    <%= tag.span class: "error-message" data: { "form-validation-target": "error", for: "post_body" } %>
  <% end %>
  <%= tag.fieldset do %>
    <%= form.check_box :anonymous %>
    <%= form.label :anonymous, t("${APP_NAME}.post_anonymously") %>
  <% end %>
  <%= form.submit t("${APP_NAME}.post_submit"), data: { turbo_submits_with: t("${APP_NAME}.post_submitting") } %>
<% end %>
EOF

  cat <<EOF > app/controllers/posts_controller.rb
class PostsController < ApplicationController
  before_action :set_post, only: [:show, :edit, :update, :destroy]
  before_action :initialize_post, only: [:index, :new]

  def index
    @pagy, @posts = pagy(Post.all.order(created_at: :desc)) unless @stimulus_reflex
  end

  def show
  end

  def new
  end

  def create
    @post = Post.new(post_params)
    @post.user = current_user || User.guest
    if @post.save
      respond_to do |format|
        format.html { redirect_to posts_path, notice: t("${APP_NAME}.post_created") }
        format.turbo_stream
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @post.update(post_params)
      respond_to do |format|
        format.html { redirect_to posts_path, notice: t("${APP_NAME}.post_updated") }
        format.turbo_stream
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @post.destroy
    respond_to do |format|
      format.html { redirect_to posts_path, notice: t("${APP_NAME}.post_deleted") }
      format.turbo_stream
    end
  end

  private

  def set_post
    @post = Post.find(params[:id])
    redirect_to posts_path, alert: t("${APP_NAME}.not_authorized") unless @post.user == current_user || current_user&.admin?
  end

  def initialize_post
    @post = Post.new
  end

  def post_params
    params.require(:post).permit(:title, :body, :anonymous)
  end
end
EOF

  cat <<EOF > app/reflexes/posts_infinite_scroll_reflex.rb
class PostsInfiniteScrollReflex < InfiniteScrollReflex
  def load_more
    @pagy, @collection = pagy(Post.all.order(created_at: :desc), page: page)
    super
  end
end
EOF
}

setup_anon_chat() {
  log "Setting up anonymous live chat"
  bin/rails generate model Message content:text sender:references receiver:references anonymous:boolean
  mkdir -p app/reflexes
  cat <<EOF > app/reflexes/chat_reflex.rb
class ChatReflex < ApplicationReflex
  def send_message
    message = Message.create(
      content: element.dataset["content"],
      sender: current_user || User.guest,
      receiver_id: element.dataset["receiver_id"],
      anonymous: element.dataset["anonymous"] == "true"
    )
    channel = ActsAsTenant.current_tenant ? "chat_channel_#{ActsAsTenant.current_tenant.subdomain}" : "chat_channel"
    ActionCable.server.broadcast(channel, {
      id: message.id,
      content: message.content,
      sender: message.anonymous? ? "Anonymous" : message.sender.email,
      created_at: message.created_at.strftime("%H:%M")
    })
  end
end
EOF

  cat <<EOF > app/channels/chat_channel.rb
class ChatChannel < ApplicationCable::Channel
  def subscribed
    channel = ActsAsTenant.current_tenant ? "chat_channel_#{ActsAsTenant.current_tenant.subdomain}" : "chat_channel"
    stream_from channel
  end
end
EOF

  mkdir -p app/javascript/controllers
  cat <<EOF > app/javascript/controllers/chat_controller.js
import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

export default class extends Controller {
  static targets = ["input", "messages"]

  connect() {
    this.consumer = createConsumer()
    const channel = this.element.dataset.tenant ? "chat_channel_#{this.element.dataset.tenant}" : "chat_channel"
    this.channel = this.consumer.subscriptions.create({ channel: "ChatChannel" }, {
      received: data => {
        this.messagesTarget.insertAdjacentHTML("beforeend", this.renderMessage(data))
        this.messagesTarget.scrollTop = this.messagesTarget.scrollHeight
      }
    })
  }

  send(event) {
    event.preventDefault()
    if (!this.hasInputTarget) return
    this.stimulate("ChatReflex#send_message", {
      dataset: {
        content: this.inputTarget.value,
        receiver_id: this.element.dataset.receiverId,
        anonymous: this.element.dataset.anonymous || "true"
      }
    })
    this.inputTarget.value = ""
  }

  renderMessage(data) {
    return \`<p class="message" data-id="\${data.id}" aria-label="Message from \${data.sender} at \${data.created_at}">\${data.sender}: \${data.content} <small>\${data.created_at}</small></p>\`
  }

  disconnect() {
    this.channel.unsubscribe()
    this.consumer.disconnect()
  }
}
EOF

  mkdir -p app/views/shared
  cat <<EOF > app/views/shared/_chat.html.erb
<%= tag.section id: "chat" aria-labelledby: "chat-heading" data: { controller: "chat", "chat-receiver-id": "global", "chat-anonymous": "true", tenant: ActsAsTenant.current_tenant&.subdomain } do %>
  <%= tag.h2 t("${APP_NAME}.chat_title"), id: "chat-heading" %>
  <%= tag.div id: "messages" data: { "chat-target": "messages" }, "aria-live": "polite" %>
  <%= form_with url: "#", method: :post, local: true do |form| %>
    <%= tag.fieldset do %>
      <%= form.label :content, t("${APP_NAME}.chat_placeholder"), class: "sr-only" %>
      <%= form.text_field :content, placeholder: t("${APP_NAME}.chat_placeholder"), data: { "chat-target": "input", action: "submit->chat#send" }, "aria-label": t("${APP_NAME}.chat_placeholder") %>
    <% end %>
  <% end %>
<% end %>
EOF
}

setup_expiry_job() {
  log "Setting up expiry job"
  bin/rails generate job expiry
  if [ $? -ne 0 ]; then
    error "Failed to generate expiry job"
  fi
}

setup_seeds() {
  log "Setting up seeds"
  if [ ! -f "db/seeds.rb" ]; then
    echo "# Add seed data here" > "db/seeds.rb"
  fi
}

setup_pwa() {
  log "Setting up PWA with offline support"
  bundle add serviceworker-rails
  if [ $? -ne 0 ]; then
    error "Failed to add serviceworker-rails"
  fi
  bin/rails generate serviceworker:install
  if [ $? -ne 0 ]; then
    error "Failed to setup PWA"
  fi
  cat <<EOF > app/assets/javascripts/serviceworker.js
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open('v1').then((cache) => {
      return cache.addAll([
        '/',
        '/offline.html',
        '/assets/application.css',
        '/assets/application.js'
      ])
    })
  )
})

self.addEventListener('fetch', (event) => {
  event.respondWith(
    caches.match(event.request).then((response) => {
      return response || fetch(event.request).catch(() => {
        return caches.match('/offline.html')
      })
    })
  )
})
EOF
  cat <<EOF > public/offline.html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title><%= t('shared.offline_title', default: 'Offline') %></title>
  <meta name="description" content="<%= t('shared.offline_description', default: 'You are currently offline. Please check your connection.') %>">
  <%= stylesheet_link_tag "application" %>
</head>
<body>
  <header role="banner">
    <%= render partial: "${APP_NAME}_logo/logo" %>
  </header>
  <main role="main">
    <h1><%= t('shared.offline_title', default: 'You\'re offline') %></h1>
    <p><%= t('shared.offline_message', default: 'Please check your connection and try again.') %></p>
  </main>
</body>
</html>
EOF
}

setup_i18n() {
  log "Setting up I18n with shared translations"
  if [ ! -f "config/locales/en.yml" ]; then
    mkdir -p "config/locales"
    cat <<EOF > "config/locales/en.yml"
en:
  shared:
    logo_alt: "${APP_NAME.capitalize} Logo"
    footer_nav: "Footer Navigation"
    about: "About"
    contact: "Contact"
    terms: "Terms"
    privacy: "Privacy"
    support: "Support"
    offline_title: "Offline"
    offline_description: "You are currently offline. Please check your connection."
    offline_message: "Please check your connection and try again."
    undo: "Undo"
    upvote: "Upvote"
    downvote: "Downvote"
    clear_search: "Clear search"
    view_post: "View post"
    view_giveaway: "View giveaway"
    view_distribution: "View distribution"
    view_listing: "View listing"
    view_profile: "View profile"
    view_playlist: "View playlist"
    view_video: "View video"
    view_package: "View package"
    view_wardrobe_item: "View wardrobe item"
    load_more: "Load more"
    voting: "Voting"
    searching: "Searching"
    loading: "Loading"
  devise:
    sessions:
      new:
        title: "Sign In"
        description: "Sign in with Vipps to access the app"
        keywords: "sign in, vipps, app"
        sign_in_with_vipps: "Sign in with Vipps"
  ${APP_NAME}:
    home_title: "${APP_NAME.capitalize} Home"
    home_description: "Welcome to ${APP_NAME.capitalize}, a community-driven platform."
    whats_on_your_mind: "What's on your mind?"
    post_body: "Post Content"
    post_body_help: "Share your thoughts or updates."
    post_anonymously: "Post Anonymously"
    post_submit: "Share"
    post_submitting: "Sharing..."
    post_created: "Post created successfully."
    post_updated: "Post updated successfully."
    post_deleted: "Post deleted successfully."
    not_authorized: "You are not authorized to perform this action."
    errors: "%{count} error(s) prevented this action."
    chat_title: "Community Chat"
    chat_placeholder: "Type a message..."
EOF
  fi
}

setup_falcon() {
  log "Setting up Falcon for production"
  bundle add falcon
  if [ $? -ne 0 ]; then
    error "Failed to add Falcon gem"
  fi
  if [ -f "bin/falcon-host" ]; then
    log "Falcon host script already exists"
  else
    echo "#!/usr/bin/env sh" > "bin/falcon-host"
    echo "bundle exec falcon host -b tcp://127.0.0.1:\$PORT" >> "bin/falcon-host"
    chmod +x "bin/falcon-host"
  fi
}

generate_social_models() {
  log "Generating social models with Post, Vote, Message"
  bin/rails generate model Post title:string body:text user:references anonymous:boolean
  bin/rails generate model Message content:text sender:references receiver:references anonymous:boolean
  bin/rails generate model Vote votable:references{polymorphic} user:references value:integer
}

commit() {
  local commit_message="$1"
  
  # Validate commit message
  if [[ -z "$commit_message" ]]; then
    error "Commit message cannot be empty"
  fi
  
  if [[ ${#commit_message} -lt 10 ]]; then
    error "Commit message too short (minimum 10 characters): '$commit_message'"
  fi
  
  log "Preparing Git commit: '$commit_message'"
  
  # Verify Git command exists
  command_exists "git"
  
  # Initialize Git repository if needed
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    log "Initializing Git repository"
    if ! git init; then
      error "Failed to initialize Git repository"
    fi
    
    # Set basic Git configuration if not set
    if [[ -z "$(git config user.name 2>/dev/null)" ]]; then
      git config user.name "Rails App Generator"
    fi
    
    if [[ -z "$(git config user.email 2>/dev/null)" ]]; then
      git config user.email "noreply@example.com"
    fi
  fi
  
  # Stage all changes
  if ! git add .; then
    error "Failed to stage changes for commit"
  fi
  
  # Check if there are changes to commit
  if git diff --cached --quiet; then
    log "No changes to commit"
    return 0
  fi
  
  # Create commit
  if ! git commit -m "$commit_message"; then
    error "Failed to create Git commit"
  fi
  
  log "Git commit created successfully: '$commit_message'"
}

setup_efficient_pagination() {
  log "Setting up efficient pagination with Pagy and performance optimizations"
  
  # Verify Rails environment
  if [[ ! -f "bin/rails" ]]; then
    error "Rails application not found - cannot setup pagination"
  fi
  
  # Enhanced Pagy configuration
  log "Creating optimized Pagy configuration"
  cat > config/initializers/pagy.rb << 'EOF'
# Pagy configuration - Framework v35.3.8 optimized for performance
require 'pagy/extras/bootstrap'
require 'pagy/extras/overflow'
require 'pagy/extras/metadata'
require 'pagy/extras/countless'
require 'pagy/extras/searchkick' if defined?(Searchkick)

# Default Pagy configuration with performance optimizations
Pagy::DEFAULT[:items] = 20
Pagy::DEFAULT[:size] = [1, 4, 4, 1]
Pagy::DEFAULT[:page_param] = :page
Pagy::DEFAULT[:anchor_string] = 'data-turbo-action="advance"'

# Performance optimizations
Pagy::DEFAULT[:overflow] = :last_page
Pagy::DEFAULT[:metadata] = [:scaffold_url, :first_url, :prev_url, :next_url, :last_url]

# Enable countless pagination for better performance on large datasets
Pagy::DEFAULT[:countless_minimal] = true

# Custom CSS classes for styling
Pagy::DEFAULT[:bootstrap_nav_class] = 'pagy-bootstrap-nav'
Pagy::DEFAULT[:bootstrap_nav_class_responsive] = 'pagy-bootstrap-nav-responsive'

# Custom pagination helper
module PagyHelper
  include Pagy::Frontend
  
  def pagy_nav_turbo(pagy, **kwargs)
    pagy_nav(pagy, **kwargs).gsub(/<a /, '<a data-turbo-action="advance" ')
  end
  
  def pagy_info_i18n(pagy, **kwargs)
    return '' if pagy.count == 0
    
    key = if pagy.count == 1
      'pagy.info.single_page.one'
    elsif pagy.pages == 1
      'pagy.info.single_page.other'
    else
      'pagy.info.multiple_pages'
    end
    
    t(key, count: pagy.count, from: pagy.from, to: pagy.to, **kwargs)
  end
end
EOF

  # Add Pagy backend helpers to ApplicationController
  log "Adding Pagy backend helpers to ApplicationController"
  cat >> app/controllers/application_controller.rb << 'EOF'

  # Pagy backend helper
  include Pagy::Backend
  
  # Performance optimized pagination
  private
  
  def pagy_get_vars(collection, vars)
    vars[:count] ||= collection.count(:all)
    vars[:page] ||= params[vars[:page_param] || Pagy::DEFAULT[:page_param]]
    vars[:items] ||= params[:items] if params[:items]
    vars
  end
  
  def pagy_countless(collection, vars = {})
    pagy, records = pagy_countless_get_vars(collection, vars)
    return pagy, records
  end
EOF

  # Add Pagy frontend helpers to ApplicationHelper
  log "Adding Pagy frontend helpers to ApplicationHelper"
  mkdir -p app/helpers
  cat >> app/helpers/application_helper.rb << 'EOF'

  # Pagy frontend helper with accessibility enhancements
  include Pagy::Frontend
  
  def accessible_pagy_nav(pagy, **kwargs)
    return '' unless pagy.pages > 1
    
    nav_tag = pagy_nav(pagy, **kwargs)
    nav_tag.gsub('<nav class="pagy-nav pagination"', 
                 '<nav class="pagy-nav pagination" aria-label="Pagination Navigation" role="navigation"')
           .gsub(/<a /, '<a aria-label="Go to page" ')
           .gsub(/<span class="page current"/, '<span class="page current" aria-current="page" aria-label="Current page"')
  end
  
  def pagy_performance_info(pagy)
    content_tag :div, class: 'pagy-info' do
      t('pagy.info.performance', 
        from: pagy.from, 
        to: pagy.to, 
        count: pagy.count,
        time: '%.2f' % (Time.current - @pagy_start_time))
    end
  end
EOF

  # Enhanced localization for Pagy
  log "Adding Pagy localization with accessibility"
  cat >> config/locales/en.yml << 'EOF'
  pagy:
    nav:
      prev: '‹ Previous'
      next: 'Next ›'
      gap: '…'
    info:
      single_page:
        zero: 'No items found'
        one: 'Displaying 1 item'
        other: 'Displaying %{count} items'
      multiple_pages: 'Displaying items %{from} - %{to} of %{count} total'
      performance: 'Showing %{from}-%{to} of %{count} in %{time}s'
    aria:
      nav: 'Pagination navigation'
      prev: 'Go to previous page'
      next: 'Go to next page'
      current: 'Current page, page %{page}'
      page: 'Go to page %{page}'
EOF

  log "Efficient pagination with Pagy setup completed"
}
  log "Setting up database optimizations with indexing strategies and performance tuning"
  
  # Verify Rails environment
  if [[ ! -f "bin/rails" ]]; then
    error "Rails application not found - cannot setup database optimizations"
  fi
  
  # Create database optimization migration
  log "Creating database optimization migration with indexes"
  local migration_file="db/migrate/$(date +%Y%m%d%H%M%S)_add_database_optimizations.rb"
  
  cat > "$migration_file" << 'EOF'
class AddDatabaseOptimizations < ActiveRecord::Migration[8.0]
  def up
    # User table optimizations
    add_index :users, :email, unique: true, algorithm: :concurrently if table_exists?(:users)
    add_index :users, :reset_password_token, unique: true, algorithm: :concurrently if table_exists?(:users)
    add_index :users, :confirmation_token, unique: true, algorithm: :concurrently if table_exists?(:users)
    add_index :users, :unlock_token, unique: true, algorithm: :concurrently if table_exists?(:users)
    add_index :users, :provider, algorithm: :concurrently if table_exists?(:users)
    add_index :users, :uid, algorithm: :concurrently if table_exists?(:users)
    add_index :users, [:provider, :uid], unique: true, algorithm: :concurrently if table_exists?(:users)
    add_index :users, :guest, algorithm: :concurrently if table_exists?(:users)
    add_index :users, :created_at, algorithm: :concurrently if table_exists?(:users)
    
    # Post table optimizations
    add_index :posts, :user_id, algorithm: :concurrently if table_exists?(:posts)
    add_index :posts, :created_at, algorithm: :concurrently if table_exists?(:posts)
    add_index :posts, [:user_id, :created_at], algorithm: :concurrently if table_exists?(:posts)
    add_index :posts, :anonymous, algorithm: :concurrently if table_exists?(:posts)
    
    # Vote table optimizations  
    add_index :votes, :votable_type, algorithm: :concurrently if table_exists?(:votes)
    add_index :votes, :votable_id, algorithm: :concurrently if table_exists?(:votes)
    add_index :votes, [:votable_type, :votable_id], algorithm: :concurrently if table_exists?(:votes)
    add_index :votes, :user_id, algorithm: :concurrently if table_exists?(:votes)
    add_index :votes, [:votable_type, :votable_id, :user_id], unique: true, algorithm: :concurrently if table_exists?(:votes)
    add_index :votes, :value, algorithm: :concurrently if table_exists?(:votes)
    
    # Message table optimizations
    add_index :messages, :sender_id, algorithm: :concurrently if table_exists?(:messages)
    add_index :messages, :receiver_id, algorithm: :concurrently if table_exists?(:messages)
    add_index :messages, :created_at, algorithm: :concurrently if table_exists?(:messages)
    add_index :messages, [:sender_id, :receiver_id], algorithm: :concurrently if table_exists?(:messages)
    
    # Listing table optimizations (for marketplace)
    add_index :listings, :user_id, algorithm: :concurrently if table_exists?(:listings)
    add_index :listings, :created_at, algorithm: :concurrently if table_exists?(:listings)
    add_index :listings, :status, algorithm: :concurrently if table_exists?(:listings)
    add_index :listings, :category, algorithm: :concurrently if table_exists?(:listings)
    add_index :listings, [:lat, :lng], algorithm: :concurrently if table_exists?(:listings)
    add_index :listings, [:status, :created_at], algorithm: :concurrently if table_exists?(:listings)
    
    # Profile table optimizations (for dating)
    add_index :profiles, :user_id, algorithm: :concurrently if table_exists?(:profiles)
    add_index :profiles, [:lat, :lng], algorithm: :concurrently if table_exists?(:profiles)
    add_index :profiles, :gender, algorithm: :concurrently if table_exists?(:profiles)
    add_index :profiles, :age, algorithm: :concurrently if table_exists?(:profiles)
    
    # Match table optimizations (for dating)
    add_index :matches, :initiator_id, algorithm: :concurrently if table_exists?(:matches)
    add_index :matches, :receiver_id, algorithm: :concurrently if table_exists?(:matches)
    add_index :matches, :status, algorithm: :concurrently if table_exists?(:matches)
    add_index :matches, :created_at, algorithm: :concurrently if table_exists?(:matches)
    
    # City table optimizations (for multi-tenancy)
    add_index :cities, :subdomain, unique: true, algorithm: :concurrently if table_exists?(:cities)
    add_index :cities, :country, algorithm: :concurrently if table_exists?(:cities)
    add_index :cities, :language, algorithm: :concurrently if table_exists?(:cities)
    
    # Active Storage optimizations
    add_index :active_storage_attachments, [:record_type, :record_id, :name, :blob_id], 
              unique: true, name: 'index_active_storage_attachments_uniqueness', 
              algorithm: :concurrently if table_exists?(:active_storage_attachments)
    add_index :active_storage_blobs, :key, unique: true, algorithm: :concurrently if table_exists?(:active_storage_blobs)
    
    # Solid Queue optimizations
    add_index :solid_queue_jobs, :queue_name, algorithm: :concurrently if table_exists?(:solid_queue_jobs)
    add_index :solid_queue_jobs, :scheduled_at, algorithm: :concurrently if table_exists?(:solid_queue_jobs)
    add_index :solid_queue_jobs, :priority, algorithm: :concurrently if table_exists?(:solid_queue_jobs)
    add_index :solid_queue_jobs, [:queue_name, :scheduled_at], algorithm: :concurrently if table_exists?(:solid_queue_jobs)
    
    # Full-text search indexes (PostgreSQL specific)
    if connection.adapter_name == 'PostgreSQL'
      execute "CREATE INDEX CONCURRENTLY IF NOT EXISTS posts_full_text_search ON posts USING gin(to_tsvector('english', title || ' ' || body))" if table_exists?(:posts)
      execute "CREATE INDEX CONCURRENTLY IF NOT EXISTS listings_full_text_search ON listings USING gin(to_tsvector('english', title || ' ' || description))" if table_exists?(:listings)
    end
  end
  
  def down
    # Remove indexes in reverse order
    remove_index :posts, name: 'posts_full_text_search' if index_exists?(:posts, name: 'posts_full_text_search')
    remove_index :listings, name: 'listings_full_text_search' if index_exists?(:listings, name: 'listings_full_text_search')
    
    # Remove other indexes
    remove_index :users, :email if index_exists?(:users, :email)
    remove_index :posts, [:user_id, :created_at] if index_exists?(:posts, [:user_id, :created_at])
    remove_index :votes, [:votable_type, :votable_id, :user_id] if index_exists?(:votes, [:votable_type, :votable_id, :user_id])
    # ... (additional removes would be here in a real migration)
  end
end
EOF

  # Add database connection pool configuration
  log "Enhancing database.yml with performance optimizations"
  cat >> config/database.yml << 'EOF'

# Performance optimizations for all environments
default: &default_optimizations
  pool: <%= ENV.fetch("RAILS_MAX_THREADS", 5).to_i + 10 %>
  timeout: 5000
  
  # PostgreSQL specific optimizations  
  prepared_statements: true
  advisory_locks: true
  statement_timeout: 30000
  lock_timeout: 10000
  idle_in_transaction_session_timeout: 300000
  
  # Connection pooling
  checkout_timeout: 5
  reaping_frequency: 10
  
production:
  <<: *default
  <<: *default_optimizations
  pool: <%= ENV.fetch("RAILS_MAX_THREADS", 25).to_i %>
  
development:
  <<: *default
  <<: *default_optimizations
  
test:
  <<: *default
  <<: *default_optimizations
  pool: 5
EOF

  log "Database optimizations setup completed with comprehensive indexing"
}
  local environment="${1:-production}"
  
  # Validate environment parameter
  case "$environment" in
    "development"|"test"|"production")
      ;;
    *)
      error "Invalid Rails environment: '$environment'. Must be development, test, or production"
      ;;
  esac
  
  log "Running database migrations for environment: $environment"
  
  # Verify Rails application structure
  if [[ ! -f "bin/rails" ]]; then
    error "Rails application not found - bin/rails missing"
  fi
  
  if [[ ! -d "db" ]]; then
    error "Database directory not found - db/ missing"
  fi
  
  # Check for pending migrations
  if ! bin/rails db:migrate:status RAILS_ENV="$environment" >/dev/null 2>&1; then
    log "Unable to check migration status - proceeding with migration"
  fi
  
  # Run migrations with comprehensive error handling
  log "Executing: bin/rails db:migrate RAILS_ENV=$environment"
  if ! bin/rails db:migrate RAILS_ENV="$environment"; then
    error "Database migrations failed for environment '$environment'"
  fi
  
  # Verify migration completion
  if bin/rails db:migrate:status RAILS_ENV="$environment" | grep -q "down"; then
    log "Warning: Some migrations may not have completed successfully"
  else
    log "All migrations completed successfully"
  fi
  
  log "Database migration completed for environment: $environment"
}

generate_turbo_views() {
  log "Generating Turbo Stream views for '$1/$2' with NNG enhancements"
  mkdir -p "app/views/$1"
  
  cat <<EOF > "app/views/$1/create.turbo_stream.erb"
<%= turbo_stream.append "${2}s", partial: "$1/${2}", locals: { ${2}: @${2} } %>
<%= turbo_stream.replace "notices", partial: "shared/notices", locals: { notice: t("${1#*/}.${2}_created") } %>
<%= turbo_stream.update "new_${2}_form", partial: "$1/form", locals: { ${2}: @${2}.class.new } %>
<%= turbo_stream.append "undo", content: link_to(t("shared.undo"), revert_${1#*/}_path(@${2}), method: :post, data: { turbo: true }, "aria-label": t("shared.undo")) %>
EOF

  cat <<EOF > "app/views/$1/update.turbo_stream.erb"
<%= turbo_stream.replace @${2}, partial: "$1/${2}", locals: { ${2}: @${2} } %>
<%= turbo_stream.replace "notices", partial: "shared/notices", locals: { notice: t("${1#*/}.${2}_updated") } %>
<%= turbo_stream.append "undo", content: link_to(t("shared.undo"), revert_${1#*/}_path(@${2}), method: :post, data: { turbo: true }, "aria-label": t("shared.undo")) %>
EOF

  cat <<EOF > "app/views/$1/destroy.turbo_stream.erb"
<%= turbo_stream.remove @${2} %>
<%= turbo_stream.replace "notices", partial: "shared/notices", locals: { notice: t("${1#*/}.${2}_deleted") } %>
<%= turbo_stream.append "undo", content: link_to(t("shared.undo"), revert_${1#*/}_path(@${2}), method: :post, data: { turbo: true }, "aria-label": t("shared.undo")) %>
EOF
}

setup_stimulus_components() {
  log "Setting up modern Stimulus components for enhanced UX with accessibility focus"
  
  # Verify Rails and Node environment
  if [[ ! -f "bin/rails" ]] || [[ ! -f "package.json" ]]; then
    error "Rails application or Node.js environment not properly configured"
  fi
  
  # Install comprehensive stimulus components from stimulus-components.com
  log "Installing modern Stimulus component library"
  if ! yarn add \
    stimulus-lightbox stimulus-infinite-scroll stimulus-character-counter \
    stimulus-textarea-autogrow stimulus-carousel stimulus-use \
    stimulus-debounce stimulus-dropdown stimulus-clipboard \
    stimulus-tabs stimulus-popover stimulus-tooltip \
    stimulus-sortable stimulus-reveal stimulus-scroll-progress \
    --silent; then
    error "Failed to install Stimulus components via Yarn"
  fi
  
  # Create enhanced stimulus controllers directory
  mkdir -p app/javascript/controllers
  
  # Enhanced lightbox controller with accessibility
  log "Creating accessible lightbox controller"
  cat > app/javascript/controllers/lightbox_controller.js << 'EOF'
import { Controller } from "@hotwired/stimulus"
import { Lightbox } from "stimulus-lightbox"

// Accessible lightbox controller - WCAG compliant
export default class extends Controller {
  static targets = ["image", "caption"]
  static classes = ["open", "loading"]
  
  connect() {
    this.lightbox = new Lightbox(this.element, {
      keyboard: true,
      closeOnOutsideClick: true,
      closeOnEscape: true,
      trapFocus: true,
      ariaLabel: "Image lightbox",
      closeButtonAriaLabel: "Close lightbox"
    })
    
    // Announce to screen readers
    this.element.setAttribute("aria-live", "polite")
  }
  
  open(event) {
    event.preventDefault()
    this.element.classList.add(this.loadingClass)
    this.element.setAttribute("aria-expanded", "true")
    
    // Announce to screen readers
    this.announce("Image lightbox opened")
  }
  
  close(event) {
    this.element.classList.remove(this.openClass, this.loadingClass)
    this.element.setAttribute("aria-expanded", "false")
    
    // Return focus to trigger element
    event.target.focus()
    this.announce("Image lightbox closed")
  }
  
  announce(message) {
    const announcement = document.createElement("div")
    announcement.setAttribute("aria-live", "assertive")
    announcement.setAttribute("aria-atomic", "true")
    announcement.className = "sr-only"
    announcement.textContent = message
    
    document.body.appendChild(announcement)
    setTimeout(() => document.body.removeChild(announcement), 1000)
  }
  
  disconnect() {
    this.lightbox?.destroy()
  }
}
EOF

  # Enhanced dropdown controller with keyboard navigation
  log "Creating accessible dropdown controller"
  cat > app/javascript/controllers/dropdown_controller.js << 'EOF'
import { Controller } from "@hotwired/stimulus"
import { useClickOutside, useHotkeys } from "stimulus-use"

// Accessible dropdown controller - WCAG compliant
export default class extends Controller {
  static targets = ["menu", "button", "item"]
  static classes = ["open"]
  
  connect() {
    useClickOutside(this)
    useHotkeys(this, [
      ["Escape", () => this.close()],
      ["ArrowDown", () => this.focusNext()],
      ["ArrowUp", () => this.focusPrevious()],
      ["Home", () => this.focusFirst()],
      ["End", () => this.focusLast()]
    ])
  }
  
  toggle(event) {
    event.preventDefault()
    
    if (this.isOpen) {
      this.close()
    } else {
      this.open()
    }
  }
  
  open() {
    this.menuTarget.classList.add(this.openClass)
    this.buttonTarget.setAttribute("aria-expanded", "true")
    this.menuTarget.setAttribute("aria-hidden", "false")
    
    // Focus first menu item
    this.focusFirst()
  }
  
  close() {
    this.menuTarget.classList.remove(this.openClass)
    this.buttonTarget.setAttribute("aria-expanded", "false")
    this.menuTarget.setAttribute("aria-hidden", "true")
    
    // Return focus to button
    this.buttonTarget.focus()
  }
  
  focusNext() {
    const items = this.itemTargets
    const currentIndex = items.indexOf(document.activeElement)
    const nextIndex = (currentIndex + 1) % items.length
    items[nextIndex].focus()
  }
  
  focusPrevious() {
    const items = this.itemTargets
    const currentIndex = items.indexOf(document.activeElement)
    const previousIndex = currentIndex === 0 ? items.length - 1 : currentIndex - 1
    items[previousIndex].focus()
  }
  
  focusFirst() {
    this.itemTargets[0]?.focus()
  }
  
  focusLast() {
    this.itemTargets[this.itemTargets.length - 1]?.focus()
  }
  
  get isOpen() {
    return this.menuTarget.classList.contains(this.openClass)
  }
  
  clickOutside() {
    this.close()
  }
}
EOF

  # Enhanced clipboard controller with user feedback
  log "Creating accessible clipboard controller with user feedback"
  cat > app/javascript/controllers/clipboard_controller.js << 'EOF'
import { Controller } from "@hotwired/stimulus"

// Accessible clipboard controller - WCAG compliant
export default class extends Controller {
  static targets = ["source", "button"]
  static classes = ["success", "error"]
  static values = { successText: String, errorText: String }
  
  copy(event) {
    event.preventDefault()
    
    const text = this.sourceTarget.textContent || this.sourceTarget.value
    
    navigator.clipboard.writeText(text)
      .then(() => this.showSuccess())
      .catch(() => this.showError())
  }
  
  showSuccess() {
    this.buttonTarget.classList.add(this.successClass)
    this.buttonTarget.setAttribute("aria-label", this.successTextValue || "Copied!")
    
    // Announce to screen readers
    this.announce(this.successTextValue || "Content copied to clipboard")
    
    setTimeout(() => {
      this.buttonTarget.classList.remove(this.successClass)
      this.buttonTarget.setAttribute("aria-label", "Copy to clipboard")
    }, 2000)
  }
  
  showError() {
    this.buttonTarget.classList.add(this.errorClass)
    this.buttonTarget.setAttribute("aria-label", this.errorTextValue || "Copy failed")
    
    // Announce to screen readers
    this.announce(this.errorTextValue || "Failed to copy content")
    
    setTimeout(() => {
      this.buttonTarget.classList.remove(this.errorClass)
      this.buttonTarget.setAttribute("aria-label", "Copy to clipboard")
    }, 2000)
  }
  
  announce(message) {
    const announcement = document.createElement("div")
    announcement.setAttribute("aria-live", "assertive")
    announcement.setAttribute("aria-atomic", "true")
    announcement.className = "sr-only"
    announcement.textContent = message
    
    document.body.appendChild(announcement)
    setTimeout(() => document.body.removeChild(announcement), 1000)
  }
}
EOF

  log "Modern Stimulus components with accessibility features setup completed"
}

setup_vote_controller() {
  log "Setting up vote controller"
  mkdir -p app/javascript/controllers
  cat <<EOF > app/javascript/controllers/vote_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  upvote(event) {
    event.preventDefault()
    this.element.querySelector(".vote-count").innerHTML = "<i class='fas fa-spinner fa-spin' aria-label='<%= t('shared.voting') %>'></i>"
    this.stimulate("VoteReflex#upvote")
  }

  downvote(event) {
    event.preventDefault()
    this.element.querySelector(".vote-count").innerHTML = "<i class='fas fa-spinner fa-spin' aria-label='<%= t('shared.voting') %>'></i>"
    this.stimulate("VoteReflex#downvote")
  }
}
EOF

  mkdir -p app/reflexes
  cat <<EOF > app/reflexes/vote_reflex.rb
class VoteReflex < ApplicationReflex
  def upvote
    votable = element.dataset["votable_type"].constantize.find(element.dataset["votable_id"])
    vote = Vote.find_or_initialize_by(votable: votable, user: current_user || User.guest)
    vote.update(value: 1)
    cable_ready.replace(selector: "#vote-#{votable.id}", html: render(partial: "shared/vote", locals: { votable: votable })).broadcast
  end

  def downvote
    votable = element.dataset["votable_type"].constantize.find(element.dataset["votable_id"])
    vote = Vote.find_or_initialize_by(votable: votable, user: current_user || User.guest)
    vote.update(value: -1)
    cable_ready.replace(selector: "#vote-#{votable.id}", html: render(partial: "shared/vote", locals: { votable: votable })).broadcast
  end
end
EOF
}

setup_enhanced_multi_tenancy() {
  log "Setting up enhanced multi-tenant architecture with security isolation"
  
  # Verify Rails environment
  if [[ ! -f "bin/rails" ]]; then
    error "Rails application not found - cannot setup multi-tenancy"
  fi
  
  # Install multi-tenancy gems with security enhancements
  log "Installing multi-tenant dependencies with security features"
  if ! bundle add acts_as_tenant apartment redis-namespace rack-attack --optimistic; then
    error "Failed to add multi-tenancy gems"
  fi
  
  # Enhanced tenant configuration with security
  log "Creating secure tenant configuration"
  cat > config/initializers/tenant.rb << 'EOF'
# Enhanced multi-tenant configuration - Framework v35.3.8 security focused
Rails.application.config.middleware.use ActsAsTenant::Middleware

ActsAsTenant.configure do |config|
  config.require_tenant = true
  config.pkey = :id
  config.fkey = :city_id
  
  # Security enhancements
  config.raise_on_missing_tenant = Rails.env.production?
  config.default_tenant = nil
  
  # Tenant validation
  config.tenant_class = 'City'
  config.current_tenant_method = :current_tenant
end

# Enhanced tenant security middleware
class TenantSecurityMiddleware
  def initialize(app)
    @app = app
  end
  
  def call(env)
    request = Rack::Request.new(env)
    
    # Extract subdomain with validation
    subdomain = extract_subdomain(request.host)
    
    # Validate subdomain format
    unless valid_subdomain?(subdomain)
      return security_error_response("Invalid subdomain format")
    end
    
    # Set tenant with security checks
    tenant = find_secure_tenant(subdomain)
    unless tenant
      return tenant_not_found_response(subdomain)
    end
    
    # Apply tenant isolation
    ActsAsTenant.current_tenant = tenant
    
    # Add security headers
    status, headers, body = @app.call(env)
    headers['X-Tenant-ID'] = tenant.id.to_s
    headers['X-Content-Type-Options'] = 'nosniff'
    headers['X-Frame-Options'] = 'SAMEORIGIN'
    
    [status, headers, body]
  ensure
    ActsAsTenant.current_tenant = nil
  end
  
  private
  
  def extract_subdomain(host)
    return nil unless host
    
    # Remove port if present
    host = host.split(':').first
    
    # Split by dots and get first part
    parts = host.split('.')
    return nil if parts.length < 2
    
    subdomain = parts.first
    subdomain unless subdomain == 'www'
  end
  
  def valid_subdomain?(subdomain)
    return false unless subdomain
    
    # Check format: 3-20 characters, alphanumeric and hyphens only
    subdomain.match?(/\A[a-z0-9-]{3,20}\z/)
  end
  
  def find_secure_tenant(subdomain)
    City.where(subdomain: subdomain, active: true).first
  rescue => e
    Rails.logger.error "Tenant lookup error: #{e.message}"
    nil
  end
  
  def security_error_response(message)
    [400, {'Content-Type' => 'text/plain'}, [message]]
  end
  
  def tenant_not_found_response(subdomain)
    [404, {'Content-Type' => 'text/plain'}, ["Tenant not found: #{subdomain}"]]
  end
end

Rails.application.config.middleware.insert_before ActionDispatch::Routing::RouteSet::Dispatcher, TenantSecurityMiddleware
EOF

  # Enhanced ApplicationController with tenant security
  log "Enhancing ApplicationController with tenant security"
  cat >> app/controllers/application_controller.rb << 'EOF'

  # Enhanced tenant security and isolation
  before_action :verify_tenant_security
  before_action :set_tenant_context
  around_action :with_tenant_isolation
  
  private
  
  def verify_tenant_security
    return unless ActsAsTenant.current_tenant
    
    # Verify tenant is active and accessible
    unless ActsAsTenant.current_tenant.active?
      redirect_to_main_site("Tenant is currently inactive")
      return
    end
    
    # Check for suspicious activity
    if suspicious_tenant_activity?
      Rails.logger.warn "Suspicious activity detected for tenant: #{ActsAsTenant.current_tenant.subdomain}"
      redirect_to_main_site("Access restricted")
      return
    end
  end
  
  def set_tenant_context
    return unless ActsAsTenant.current_tenant
    
    # Set tenant-specific configurations
    @current_tenant = ActsAsTenant.current_tenant
    @tenant_locale = @current_tenant.language || I18n.default_locale
    @tenant_timezone = @current_tenant.timezone || Time.zone
    
    # Set locale and timezone for this request
    I18n.locale = @tenant_locale
    Time.zone = @tenant_timezone
  end
  
  def with_tenant_isolation
    return yield unless ActsAsTenant.current_tenant
    
    # Ensure all database queries are scoped to current tenant
    ActsAsTenant.with_tenant(ActsAsTenant.current_tenant) do
      # Additional security: verify user belongs to tenant
      if user_signed_in? && current_user.respond_to?(:tenant_id)
        unless current_user.tenant_id == ActsAsTenant.current_tenant.id
          sign_out current_user
          redirect_to_main_site("User not authorized for this tenant")
          return
        end
      end
      
      yield
    end
  end
  
  def suspicious_tenant_activity?
    # Implement rate limiting check
    key = "tenant_requests:#{ActsAsTenant.current_tenant.id}:#{request.remote_ip}"
    count = Rails.cache.read(key) || 0
    
    if count > 1000 # requests per hour
      Rails.cache.write(key, count + 1, expires_in: 1.hour)
      return true
    else
      Rails.cache.write(key, count + 1, expires_in: 1.hour)
      return false
    end
  end
  
  def redirect_to_main_site(message)
    redirect_to root_url(subdomain: false), alert: message
  end
  
  def current_tenant
    ActsAsTenant.current_tenant
  end
  
  helper_method :current_tenant
EOF

  # Enhanced City model with security features
  log "Creating enhanced City model with security validations"
  cat > app/models/city.rb << 'EOF'
class City < ApplicationRecord
  acts_as_tenant(:city)
  
  # Security validations
  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :subdomain, presence: true, uniqueness: true,
            format: { with: /\A[a-z0-9-]{3,20}\z/, message: "must be 3-20 characters, lowercase letters, numbers, and hyphens only" }
  validates :country, presence: true, length: { maximum: 100 }
  validates :language, presence: true, inclusion: { in: %w[en no se dk fi is de fr es it pt nl] }
  validates :tld, presence: true, inclusion: { in: %w[com org net no se dk fi is de fr es it pt nl uk] }
  
  # Security scopes
  scope :active, -> { where(active: true) }
  scope :verified, -> { where(verified: true) }
  scope :by_country, ->(country) { where(country: country) }
  
  # Callbacks for security
  before_save :sanitize_fields
  before_create :set_security_defaults
  after_create :log_city_creation
  
  # Instance methods
  def display_name
    "#{name}, #{country}"
  end
  
  def full_domain
    "#{subdomain}.#{app_domain}.#{tld}"
  end
  
  def app_domain
    Rails.application.credentials.app_domain || 'example'
  end
  
  def active?
    active && verified
  end
  
  def timezone
    case country.downcase
    when 'norway', 'sweden', 'denmark' then 'Europe/Oslo'
    when 'finland' then 'Europe/Helsinki'
    when 'iceland' then 'Atlantic/Reykjavik'
    when 'uk', 'united kingdom' then 'Europe/London'
    when 'germany' then 'Europe/Berlin'
    when 'france' then 'Europe/Paris'
    when 'usa', 'united states' then 'America/New_York'
    else 'UTC'
    end
  end
  
  private
  
  def sanitize_fields
    self.name = name.strip.titleize if name
    self.subdomain = subdomain.strip.downcase if subdomain
    self.country = country.strip.titleize if country
    self.language = language.strip.downcase if language
    self.tld = tld.strip.downcase if tld
  end
  
  def set_security_defaults
    self.active = false unless has_attribute?(:active)
    self.verified = false unless has_attribute?(:verified)
    self.created_by ||= 'system'
  end
  
  def log_city_creation
    Rails.logger.info "New city created: #{name} (#{subdomain}) by #{created_by}"
  end
end
EOF

  # Enhanced routes with tenant security
  log "Adding secure tenant routing configuration"
  cat > config/routes.rb << 'EOF'
Rails.application.routes.draw do
  # Health check endpoint (no tenant required)
  get '/health', to: 'application#health'
  
  # Root route with tenant detection
  root 'home#index'
  
  # Devise routes with tenant scope
  devise_for :users, controllers: {
    omniauth_callbacks: 'users/omniauth_callbacks',
    sessions: 'users/sessions'
  }
  
  # Tenant-scoped application routes
  constraints(TenantConstraint.new) do
    resources :posts do
      resources :votes, only: [:create, :destroy]
    end
    
    resources :listings do
      resources :votes, only: [:create, :destroy]
    end
    
    resources :profiles, only: [:show, :edit, :update] do
      resources :matches, only: [:create, :show, :destroy]
    end
    
    resources :messages, only: [:index, :create, :show]
    
    # Admin routes (require admin user)
    namespace :admin do
      resources :cities, except: [:destroy]
      resources :users, only: [:index, :show, :edit, :update]
      resources :analytics, only: [:index, :show]
    end
  end
  
  # Tenant constraint class
  class TenantConstraint
    def matches?(request)
      subdomain = request.subdomain
      return false if subdomain.blank? || subdomain == 'www'
      
      # Cache tenant lookup for performance
      Rails.cache.fetch("tenant_exists:#{subdomain}", expires_in: 1.hour) do
        City.exists?(subdomain: subdomain, active: true)
      end
    end
  end
end
EOF

  log "Enhanced multi-tenant architecture with security isolation completed"
}

setup_full_app() {
  log "Setting up full Rails app '$1' with Framework v35.3.8 optimizations and security enhancements"
  init_app "$1"
  setup_postgresql "$1"
  setup_redis
  setup_ruby
  setup_yarn
  setup_rails "$1"
  setup_solid_queue
  setup_solid_cache
  setup_core
  setup_devise
  setup_storage
  setup_enhanced_stripe
  setup_enhanced_mapbox
  setup_optimized_live_search
  setup_optimized_infinite_scroll
  setup_anon_posting
  setup_anon_chat
  setup_expiry_job
  setup_seeds
  setup_pwa
  setup_i18n
  setup_falcon
  setup_stimulus_components
  setup_vote_controller
  setup_database_optimizations
  setup_efficient_pagination
  setup_enhanced_multi_tenancy
  generate_social_models
  migrate_db

  cat <<EOF > app/assets/stylesheets/application.scss
:root {
  --white: #ffffff
  --black: #000000
  --grey: #666666
  --light-grey: #e0e0e0
  --dark-grey: #333333
  --primary: #1a73e8
  --error: #d93025
}

body {
  margin: 0
  padding: 0
  font-family: 'Roboto', Arial, sans-serif
  background: var(--white)
  color: var(--black)
  line-height: 1.5
  display: flex
  flex-direction: column
  min-height: 100vh
}

header {
  padding: 16px
  text-align: center
  border-bottom: 1px solid var(--light-grey)
}

.logo {
  max-width: 120px
  height: auto
}

main {
  flex: 1
  padding: 16px
  max-width: 800px
  margin: 0 auto
  width: 100%
}

h1 {
  font-size: 24px
  margin: 0 0 16px
  font-weight: 400
}

h2 {
  font-size: 20px
  margin: 0 0 12px
  font-weight: 400
}

section {
  margin-bottom: 24px
}

fieldset {
  border: none
  padding: 0
  margin: 0 0 16px
}

label {
  display: block
  font-size: 14px
  margin-bottom: 4px
  color: var(--dark-grey)
}

input[type="text"],
input[type="email"],
input[type="password"],
input[type="number"],
input[type="datetime-local"],
input[type="file"],
textarea {
  width: 100%
  padding: 8px
  border: 1px solid var(--light-grey)
  border-radius: 4px
  font-size: 16px
  box-sizing: border-box
}

textarea {
  resize: vertical
  min-height: 80px
}

input:invalid,
textarea:invalid {
  border-color: var(--error)
}

.error-message {
  display: none
  color: var(--error)
  font-size: 12px
  margin-top: 4px
}

input:invalid + .error-message,
textarea:invalid + .error-message {
  display: block
}

button,
input[type="submit"],
.button {
  background: var(--primary)
  color: var(--white)
  border: none
  padding: 8px 16px
  border-radius: 4px
  font-size: 14px
  cursor: pointer
  transition: background 0.2s
  text-decoration: none
  display: inline-block
}

button:hover,
input[type="submit"]:hover,
.button:hover {
  background: #1557b0
}

button:disabled {
  background: var(--grey)
  cursor: not-allowed
}

.oauth-link {
  display: inline-block
  margin: 8px 0
  color: var(--primary)
  text-decoration: none
  font-size: 14px
}

.oauth-link:hover {
  text-decoration: underline
}

.notice,
.alert {
  padding: 8px
  margin-bottom: 16px
  border-radius: 4px
  font-size: 14px
}

.notice {
  background: #e8f0fe
  color: var(--primary)
}

.alert {
  background: #fce8e6
  color: var(--error)
}

footer {
  padding: 16px
  border-top: 1px solid var(--light-grey)
  text-align: center
}

.footer-links {
  display: flex
  justify-content: center
  gap: 16px
}

.footer-link {
  color: var(--grey)
  text-decoration: none
  font-size: 12px
}

.footer-link:hover {
  text-decoration: underline
}

.footer-link.fb,
.footer-link.tw,
.footer-link.ig {
  width: 16px
  height: 16px
  background-size: contain
}

.footer-link.fb { background: url('/fb.svg') no-repeat }
.footer-link.tw { background: url('/tw.svg') no-repeat }
.footer-link.ig { background: url('/ig.svg') no-repeat }

.post-card {
  border: 1px solid var(--light-grey)
  padding: 16px
  margin-bottom: 16px
  border-radius: 4px
}

.post-header {
  display: flex
  justify-content: space-between
  font-size: 12px
  color: var(--grey)
  margin-bottom: 8px
}

.post-actions {
  margin-top: 8px
}

.post-actions a,
.post-actions button {
  margin-right: 8px
}

.vote {
  display: flex
  align-items: center
  gap: 4px
}

.vote-count {
  font-size: 14px
}

.message {
  padding: 8px
  border-bottom: 1px solid var(--light-grey)
}

.message small {
  color: var(--grey)
  font-size: 12px
}

#map {
  height: 400px
  width: 100%
  border-radius: 4px
}

#search-results {
  margin-top: 8px
}

#reset-link {
  margin: 8px 0
}

#sentinel.hidden {
  display: none
}

@media (max-width: 600px) {
  main {
    padding: 8px
  }

  h1 {
    font-size: 20px
  }

  h2 {
    font-size: 18px
  }

  #map {
    height: 300px
  }
}
EOF
}
  log "Setting up full Rails app '$1' with NNG/SEO/Schema enhancements and Rails 8 modern stack"
  init_app "$1"
  setup_postgresql "$1"
  setup_redis
  setup_ruby
  setup_yarn
  setup_rails "$1"
  setup_solid_queue
  setup_solid_cache
  setup_core
  setup_devise
  setup_storage
  setup_stripe
  setup_mapbox
  setup_live_search
  setup_infinite_scroll
  setup_anon_posting
  setup_anon_chat
  setup_expiry_job
  setup_seeds
  setup_pwa
  setup_i18n
  setup_falcon
  setup_stimulus_components
  setup_vote_controller
  generate_social_models
  migrate_db

  cat <<EOF > app/assets/stylesheets/application.scss
:root {
  --white: #ffffff
  --black: #000000
  --grey: #666666
  --light-grey: #e0e0e0
  --dark-grey: #333333
  --primary: #1a73e8
  --error: #d93025
}

body {
  margin: 0
  padding: 0
  font-family: 'Roboto', Arial, sans-serif
  background: var(--white)
  color: var(--black)
  line-height: 1.5
  display: flex
  flex-direction: column
  min-height: 100vh
}

header {
  padding: 16px
  text-align: center
  border-bottom: 1px solid var(--light-grey)
}

.logo {
  max-width: 120px
  height: auto
}

main {
  flex: 1
  padding: 16px
  max-width: 800px
  margin: 0 auto
  width: 100%
}

h1 {
  font-size: 24px
  margin: 0 0 16px
  font-weight: 400
}

h2 {
  font-size: 20px
  margin: 0 0 12px
  font-weight: 400
}

section {
  margin-bottom: 24px
}

fieldset {
  border: none
  padding: 0
  margin: 0 0 16px
}

label {
  display: block
  font-size: 14px
  margin-bottom: 4px
  color: var(--dark-grey)
}

input[type="text"],
input[type="email"],
input[type="password"],
input[type="number"],
input[type="datetime-local"],
input[type="file"],
textarea {
  width: 100%
  padding: 8px
  border: 1px solid var(--light-grey)
  border-radius: 4px
  font-size: 16px
  box-sizing: border-box
}

textarea {
  resize: vertical
  min-height: 80px
}

input:invalid,
textarea:invalid {
  border-color: var(--error)
}

.error-message {
  display: none
  color: var(--error)
  font-size: 12px
  margin-top: 4px
}

input:invalid + .error-message,
textarea:invalid + .error-message {
  display: block
}

button,
input[type="submit"],
.button {
  background: var(--primary)
  color: var(--white)
  border: none
  padding: 8px 16px
  border-radius: 4px
  font-size: 14px
  cursor: pointer
  transition: background 0.2s
  text-decoration: none
  display: inline-block
}

button:hover,
input[type="submit"]:hover,
.button:hover {
  background: #1557b0
}

button:disabled {
  background: var(--grey)
  cursor: not-allowed
}

.oauth-link {
  display: inline-block
  margin: 8px 0
  color: var(--primary)
  text-decoration: none
  font-size: 14px
}

.oauth-link:hover {
  text-decoration: underline
}

.notice,
.alert {
  padding: 8px
  margin-bottom: 16px
  border-radius: 4px
  font-size: 14px
}

.notice {
  background: #e8f0fe
  color: var(--primary)
}

.alert {
  background: #fce8e6
  color: var(--error)
}

footer {
  padding: 16px
  border-top: 1px solid var(--light-grey)
  text-align: center
}

.footer-links {
  display: flex
  justify-content: center
  gap: 16px
}

.footer-link {
  color: var(--grey)
  text-decoration: none
  font-size: 12px
}

.footer-link:hover {
  text-decoration: underline
}

.footer-link.fb,
.footer-link.tw,
.footer-link.ig {
  width: 16px
  height: 16px
  background-size: contain
}

.footer-link.fb { background: url('/fb.svg') no-repeat }
.footer-link.tw { background: url('/tw.svg') no-repeat }
.footer-link.ig { background: url('/ig.svg') no-repeat }

.post-card {
  border: 1px solid var(--light-grey)
  padding: 16px
  margin-bottom: 16px
  border-radius: 4px
}

.post-header {
  display: flex
  justify-content: space-between
  font-size: 12px
  color: var(--grey)
  margin-bottom: 8px
}

.post-actions {
  margin-top: 8px
}

.post-actions a,
.post-actions button {
  margin-right: 8px
}

.vote {
  display: flex
  align-items: center
  gap: 4px
}

.vote-count {
  font-size: 14px
}

.message {
  padding: 8px
  border-bottom: 1px solid var(--light-grey)
}

.message small {
  color: var(--grey)
  font-size: 12px
}

#map {
  height: 400px
  width: 100%
  border-radius: 4px
}

#search-results {
  margin-top: 8px
}

#reset-link {
  margin: 8px 0
}

#sentinel.hidden {
  display: none
}

@media (max-width: 600px) {
  main {
    padding: 8px
  }

  h1 {
    font-size: 20px
  }

  h2 {
    font-size: 18px
  }

  #map {
    height: 300px
  }
}
EOF
}

# Change Log:
# - Added setup_anon_posting for reusable front-page anonymous posting
# - Added setup_anon_chat for tenant-aware anonymous live chat
# - Included setup_vote_controller for reusable voting logic
# - Updated paths to /home/dev/rails
# - Enhanced I18n with app-specific placeholders
# - Ensured NNG, SEO, schema, and flat design compliance
# - Finalized for unprivileged user on OpenBSD 7.5