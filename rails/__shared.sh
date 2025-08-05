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

setup_stripe() {
  log "Setting up Stripe"
  bundle add stripe
  if [ $? -ne 0 ]; then
    error "Failed to add Stripe gem"
  fi
}

setup_mapbox() {
  log "Setting up Mapbox"
  bundle add mapbox-gl-rails
  if [ $? -ne 0 ]; then
    error "Failed to install Mapbox gem"
  fi
  yarn add mapbox-gl mapbox-gl-geocoder
  if [ $? -ne 0 ]; then
    error "Failed to install Mapbox JS"
  fi
  echo "//= require mapbox-gl" >> app/assets/javascripts/application.js
  echo "//= require mapbox-gl-geocoder" >> app/assets/javascripts/application.js
  echo "/* *= require mapbox-gl */" >> app/assets/stylesheets/application.css
  echo "/* *= require mapbox-gl-geocoder */" >> app/assets/stylesheets/application.css
}

setup_live_search() {
  log "Setting up live search with StimulusReflex"
  bundle add stimulus_reflex
  if [ $? -ne 0 ]; then
    error "Failed to add StimulusReflex"
  fi
  bin/rails stimulus_reflex:install
  if [ $? -ne 0 ]; then
    error "Failed to install StimulusReflex"
  fi
  yarn add stimulus-debounce
  if [ $? -ne 0 ]; then
    error "Failed to install stimulus-debounce"
  fi

  mkdir -p app/reflexes
  cat <<EOF > app/reflexes/search_reflex.rb
class SearchReflex < ApplicationReflex
  def search(query = "")
    model = element.dataset["model"].constantize
    field = element.dataset["field"]
    results = model.where("\#{field} ILIKE ?", "%\#{query}%")
    morph "\#search-results", render(partial: "shared/search_results", locals: { results: results, model: model.downcase })
    morph "\#reset-link", render(partial: "shared/reset_link", locals: { query: query })
  end
end
EOF

  mkdir -p app/javascript/controllers
  cat <<EOF > app/javascript/controllers/search_controller.js
import { Controller } from "@hotwired/stimulus"
import debounce from "stimulus-debounce"

export default class extends Controller {
  static targets = ["input", "results"]

  connect() {
    this.search = debounce(this.search, 200).bind(this)
  }

  search(event) {
    if (!this.hasInputTarget) {
      console.error("SearchController: Input target not found")
      return
    }
    this.resultsTarget.innerHTML = "<i class='fas fa-spinner fa-spin' aria-label='<%= t('shared.searching') %>'></i>"
    this.stimulate("SearchReflex#search", this.inputTarget.value)
  }

  reset(event) {
    event.preventDefault()
    this.inputTarget.value = ""
    this.stimulate("SearchReflex#search")
  }

  beforeSearch() {
    this.resultsTarget.animate(
      [{ opacity: 0 }, { opacity: 1 }],
      { duration: 300 }
    )
  }
}
EOF

  mkdir -p app/views/shared
  cat <<EOF > app/views/shared/_search_results.html.erb
<% results.each do |result| %>
  <%= tag.p do %>
    <%= link_to result.send(element.dataset["field"]), "/\#{model}s/\#{result.id}", "aria-label": t("shared.view_\#{model}", name: result.send(element.dataset["field"])) %>
  <% end %>
<% end %>
EOF

  cat <<EOF > app/views/shared/_reset_link.html.erb
<% if query.present? %>
  <%= link_to t("shared.clear_search"), "#", data: { action: "click->search#reset" }, "aria-label": t("shared.clear_search") %>
<% end %>
EOF
}

setup_infinite_scroll() {
  log "Setting up infinite scroll with StimulusReflex"
  bundle add stimulus_reflex cable_ready pagy
  if [ $? -ne 0 ]; then
    error "Failed to add infinite scroll gems"
  fi
  yarn add stimulus-use
  if [ $? -ne 0 ]; then
    error "Failed to install stimulus-use"
  fi

  mkdir -p app/reflexes
  cat <<EOF > app/reflexes/infinite_scroll_reflex.rb
class InfiniteScrollReflex < ApplicationReflex
  include Pagy::Backend

  attr_reader :collection

  def load_more
    cable_ready.insert_adjacent_html(
      selector: selector,
      html: render(collection, layout: false),
      position: position
    ).broadcast
  end

  def page
    element.dataset["next_page"].to_i
  end

  def position
    "beforebegin"
  end

  def selector
    "#sentinel"
  end
end
EOF

  mkdir -p app/javascript/controllers
  cat <<EOF > app/javascript/controllers/infinite_scroll_controller.js
import { Controller } from "@hotwired/stimulus"
import { useIntersection } from "stimuse"

export default class extends Controller {
  static targets = ["sentinel"]

  connect() {
    useIntersection(this, { element: this.sentinelTarget })
  }

  appear() {
    this.sentinelTarget.disabled = true
    this.sentinelTarget.innerHTML = '<i class="fas fa-spinner fa-spin" aria-label="<%= t("shared.loading") %>"></i>'
    this.stimulate("InfiniteScroll#load_more", this.sentinelTarget)
  }
}
EOF
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

migrate_db() {
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

setup_full_app() {
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