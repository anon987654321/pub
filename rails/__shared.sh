#!/usr/bin/env zsh
set -euo pipefail

# Production-ready shared utility functions for Rails 8 apps on OpenBSD 7.5
# Enhanced with PWA, analytics, rich text, karma system, caching, error handling
# Following prompts.json standards for production deployment

BASE_DIR="/home/dev/rails"
RAILS_VERSION="8.0.0"
RUBY_VERSION="3.3.0"
NODE_VERSION="20"
BRGEN_IP="46.23.95.45"

# Production configuration
export RAILS_ENV="${RAILS_ENV:-production}"
export NODE_ENV="${NODE_ENV:-production}"
export RACK_ENV="${RACK_ENV:-production}"

log() {
  local app_name="${APP_NAME:-unknown}"
  local timestamp=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
  local log_dir="$BASE_DIR/$app_name/log"
  mkdir -p "$log_dir"
  echo "$timestamp - [INFO] $1" | tee -a "$log_dir/setup.log" "$log_dir/production.log"
  echo "[$(date +'%H:%M:%S')] $1"
}

error() {
  local app_name="${APP_NAME:-unknown}"
  local timestamp=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
  local log_dir="$BASE_DIR/$app_name/log"
  mkdir -p "$log_dir"
  echo "$timestamp - [ERROR] $1" | tee -a "$log_dir/setup.log" "$log_dir/error.log" >&2
  echo "[ERROR] $1" >&2
  exit 1
}

warn() {
  local app_name="${APP_NAME:-unknown}"
  local timestamp=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
  local log_dir="$BASE_DIR/$app_name/log"
  mkdir -p "$log_dir"
  echo "$timestamp - [WARN] $1" | tee -a "$log_dir/setup.log" "$log_dir/production.log" >&2
  echo "[WARN] $1" >&2
}

command_exists() {
  command -v "$1" > /dev/null 2>&1
  if [ $? -ne 0 ]; then
    error "Command '$1' not found. Please install it. Run: pkg_add $1 (OpenBSD) or brew install $1 (macOS)"
  fi
}

check_system_requirements() {
  log "Checking system requirements for production deployment"
  
  # Check available memory (minimum 2GB recommended)
  local memory_kb=$(sysctl -n hw.physmem 2>/dev/null | awk '{print int($1/1024)}' || echo "0")
  if [ "$memory_kb" -lt 2097152 ]; then
    warn "System has less than 2GB RAM. Performance may be impacted."
  fi
  
  # Check disk space (minimum 10GB recommended)
  local disk_available=$(df -h "$BASE_DIR" 2>/dev/null | tail -1 | awk '{print $4}' | sed 's/[^0-9.]//g' || echo "0")
  if [ "${disk_available%.*}" -lt 10 ]; then
    warn "Less than 10GB disk space available. Consider freeing up space."
  fi
  
  # Check required commands
  command_exists "ruby"
  command_exists "node"
  command_exists "psql"
  command_exists "redis-server"
  command_exists "git"
  
  log "System requirements check completed"
}

init_app() {
  log "Initializing app directory for '$1'"
  mkdir -p "$BASE_DIR/$1"
  if [ $? -ne 0 ]; then
    error "Failed to create app directory '$BASE_DIR/$1'"
  fi
  cd "$BASE_DIR/$1"
  if [ $? -ne 0 ]; then
    error "Failed to change to directory '$BASE_DIR/$1'"
  fi
}

setup_ruby() {
  log "Setting up Ruby $RUBY_VERSION"
  command_exists "ruby"
  if ! ruby -v | grep -q "$RUBY_VERSION"; then
    error "Ruby $RUBY_VERSION not found. Please install it manually (e.g., pkg_add ruby-$RUBY_VERSION)."
  fi
  gem install bundler
  if [ $? -ne 0 ]; then
    error "Failed to install Bundler"
  fi
}

setup_yarn() {
  log "Setting up Node.js $NODE_VERSION and Yarn"
  command_exists "node"
  if ! node -v | grep -q "v$NODE_VERSION"; then
    error "Node.js $NODE_VERSION not found. Please install it manually (e.g., pkg_add node-$NODE_VERSION)."
  fi
  npm install -g yarn
  if [ $? -ne 0 ]; then
    error "Failed to install Yarn"
  fi
}

setup_rails() {
  log "Setting up Rails $RAILS_VERSION for '$1' with production enhancements"
  if [ -f "Gemfile" ]; then
    log "Gemfile exists, updating dependencies"
    bundle update
  else
    rails new . -f --skip-bundle --database=postgresql --asset-pipeline=propshaft --css=scss \
      --skip-test --skip-system-test --skip-bootsnap
    if [ $? -ne 0 ]; then
      error "Failed to create Rails app '$1'"
    fi
  fi
  
  # Add production-ready Rails 8 gems to Gemfile
  cat <<EOF >> Gemfile

# Rails 8 Production Stack
gem 'solid_queue', '~> 1.0'
gem 'solid_cache', '~> 1.0'
gem 'solid_cable', '~> 1.0'
gem 'falcon', '~> 0.47'
gem 'kamal', '~> 2.0'

# Modern Frontend Stack
gem 'hotwire-rails', '~> 0.1'
gem 'turbo-rails', '~> 2.0'
gem 'stimulus-rails', '~> 1.3'
gem 'stimulus_reflex', '~> 3.5'
gem 'cable_ready', '~> 5.0'
gem 'propshaft', '~> 1.0'

# Rich Text & Content
gem 'action_text', '~> 8.0'
gem 'image_processing', '~> 1.0'
gem 'acts_as_votable', '~> 0.14'
gem 'acts_as_commentable_with_threading', '~> 2.0'

# Search & Analytics
gem 'pg_search', '~> 2.3'
gem 'ahoy_matey', '~> 5.0'
gem 'searchkick', '~> 5.3'

# Performance & Monitoring
gem 'bootsnap', '~> 1.18', require: false
gem 'rack-mini-profiler', '~> 3.3'
gem 'memory_profiler', '~> 1.0'
gem 'skylight', '~> 6.0'

# Security & Authentication
gem 'devise', '~> 4.9'
gem 'omniauth-vipps', '~> 0.1'
gem 'devise-guests', '~> 0.8'
gem 'brakeman', '~> 6.1'
gem 'bundler-audit', '~> 0.9'

# Production Infrastructure
gem 'redis', '~> 5.0'
gem 'hiredis-client', '~> 0.22'
gem 'connection_pool', '~> 2.4'

group :production do
  gem 'lograge', '~> 0.14'
  gem 'amazing_print', '~> 1.6'
end

group :development do
  gem 'annotate', '~> 3.2'
  gem 'rails_layout', '~> 1.6'
end
EOF

  bundle install
  if [ $? -ne 0 ]; then
    error "Failed to run bundle install"
  fi
  
  log "Rails setup completed with production enhancements"
}

setup_postgresql() {
  log "Checking PostgreSQL for '$1'"
  command_exists "psql"
  if ! psql -l | grep -q "$1"; then
    log "Database '$1' not found. Please create it manually (e.g., createdb $1) before proceeding."
    error "Database setup incomplete"
  fi
}

setup_redis() {
  log "Verifying Redis for '$1'"
  command_exists "redis-server"
  if ! pgrep redis-server > /dev/null; then
    log "Redis not running. Please start it manually (e.g., redis-server &) before proceeding."
    error "Redis not running"
  fi
}

setup_solid_queue() {
  log "Setting up Solid Queue for background jobs"
  
  # Generate Solid Queue configuration
  bin/rails generate solid_queue:install
  if [ $? -ne 0 ]; then
    error "Failed to generate Solid Queue configuration"
  fi
  
  # Configure Solid Queue in application.rb
  cat <<EOF >> config/application.rb

    # Solid Queue configuration
    config.active_job.queue_adapter = :solid_queue
    config.solid_queue.connects_to = { writing: :primary }
EOF

  # Add database configuration for Solid Queue
  cat <<EOF >> config/database.yml

# Solid Queue database configuration
solid_queue:
  <<: *default
  database: <%= ENV.fetch('DATABASE_URL', "#{Rails.application.credentials.database_url || 'postgresql://localhost/solid_queue'}") %>
  migrations_paths: db/queue_migrate
EOF

  log "Solid Queue setup completed"
}

setup_solid_cache() {
  log "Setting up Solid Cache for caching"
  
  # Generate Solid Cache configuration
  bin/rails generate solid_cache:install
  if [ $? -ne 0 ]; then
    error "Failed to generate Solid Cache configuration"
  fi
  
  # Configure Solid Cache in application.rb
  cat <<EOF >> config/application.rb

    # Solid Cache configuration
    config.cache_store = :solid_cache_store
EOF

  # Add Solid Cache initializer
  cat <<EOF > config/initializers/solid_cache.rb
# Solid Cache configuration
Rails.application.configure do
  config.solid_cache.connects_to = { writing: :primary }
  config.solid_cache.key_hash_stage = :fnv1a_64
  config.solid_cache.encrypt = true
  config.solid_cache.size_limit = 256.megabytes
end
EOF

  log "Solid Cache setup completed"
}

install_gem() {
  log "Installing gem '$1'"
  if ! gem list | grep -q "$1"; then
    gem install "$1"
    if [ $? -ne 0 ]; then
      error "Failed to install gem '$1'"
    fi
    echo "gem \"$1\"" >> Gemfile
    bundle install
    if [ $? -ne 0 ]; then
      error "Failed to bundle gem '$1'"
    fi
  fi
}

setup_production_monitoring() {
  log "Setting up production monitoring and error tracking"
  
  # Setup error monitoring with Skylight and custom error handling
  cat <<EOF > config/initializers/error_monitoring.rb
# Production error monitoring configuration
Rails.application.configure do
  # Skylight monitoring
  config.skylight.environments = ['production', 'staging']
  config.skylight.probes = ['redis', 'action_cable', 'active_job']
  
  # Custom error handling
  config.exceptions_app = ->(env) {
    ErrorsController.action(:show).call(env)
  }
  
  # Log structured data
  config.lograge.enabled = true
  config.lograge.formatter = Lograge::Formatters::Json.new
  config.lograge.custom_options = lambda do |event|
    {
      time: Time.current.iso8601,
      user_id: event.payload[:user_id],
      request_id: event.payload[:request_id],
      ip: event.payload[:ip]
    }
  end
end
EOF

  # Create error controller for custom error pages
  cat <<EOF > app/controllers/errors_controller.rb
class ErrorsController < ApplicationController
  layout 'error'
  
  def show
    @status_code = params[:code] || 500
    render view_for_code(@status_code), status: @status_code
  end
  
  private
  
  def view_for_code(code)
    case code.to_s
    when '404' then 'not_found'
    when '422' then 'unprocessable_entity' 
    when '500' then 'internal_server_error'
    else 'internal_server_error'
    end
  end
end
EOF

  # Create error views
  mkdir -p app/views/errors
  cat <<EOF > app/views/errors/not_found.html.erb
<% content_for :title, t('errors.not_found.title') %>
<%= tag.main role: "main", class: "error-page" do %>
  <%= tag.section aria_labelledby: "error-heading" do %>
    <%= tag.h1 t('errors.not_found.title'), id: "error-heading" %>
    <%= tag.p t('errors.not_found.message') %>
    <%= link_to t('errors.go_home'), root_path, class: "button primary" %>
  <% end %>
<% end %>
EOF

  log "Production monitoring setup completed"
}

setup_analytics() {
  log "Setting up analytics and visitor tracking"
  
  # Configure Ahoy for visitor analytics
  bin/rails generate ahoy:install --skip-migration
  
  cat <<EOF > config/initializers/ahoy.rb
class Ahoy::Store < Ahoy::DatabaseStore
  def track_visit(data)
    data[:ip] = request.remote_ip if request&.remote_ip
    data[:user_agent] = request.user_agent if request&.user_agent
    super(data)
  end
  
  def track_event(data)
    data[:user_id] = current_user&.id
    super(data)
  end
end

Ahoy.api = true
Ahoy.mask_ips = true
Ahoy.cookies = :none
Ahoy.server_side_visits = :when_needed
EOF

  # Add analytics tracking to application layout
  cat <<EOF > app/views/shared/_analytics.html.erb
<% if Rails.env.production? %>
  <%= javascript_tag do %>
    // Track page views
    ahoy.track("Page View", {
      page: "<%= request.path %>",
      title: "<%= yield(:title) || 'Page' %>",
      referrer: document.referrer
    });
    
    // Track user interactions  
    document.addEventListener('click', function(e) {
      if (e.target.matches('button, a, input[type="submit"]')) {
        ahoy.track("Click", {
          element: e.target.tagName.toLowerCase(),
          text: e.target.textContent || e.target.value,
          url: e.target.href || window.location.href
        });
      }
    });
  <% end %>
<% end %>
EOF

  log "Analytics setup completed"
}

setup_rich_text() {
  log "Setting up Action Text for rich text editing"
  
  # Install Action Text
  bin/rails action_text:install
  
  # Configure Trix editor with custom styling
  cat <<EOF > app/assets/stylesheets/action_text.scss
// Action Text rich text editor styles
.trix-editor {
  border: 1px solid #e0e0e0;
  border-radius: 4px;
  padding: 1rem;
  min-height: 120px;
  font-family: inherit;
  font-size: 1rem;
  line-height: 1.5;
}

.trix-editor:focus {
  border-color: #1a73e8;
  outline: none;
  box-shadow: 0 0 0 2px rgba(26, 115, 232, 0.2);
}

.trix-content {
  h1, h2, h3 { margin: 1rem 0 0.5rem; }
  p { margin: 0.5rem 0; }
  ul, ol { margin: 0.5rem 0; padding-left: 2rem; }
  blockquote { 
    margin: 1rem 0; 
    padding-left: 1rem; 
    border-left: 4px solid #e0e0e0;
    color: #666;
  }
}

.trix-toolbar {
  border: 1px solid #e0e0e0;
  border-bottom: none;
  border-radius: 4px 4px 0 0;
  background: #f8f9fa;
  padding: 0.5rem;
}

.trix-toolbar .trix-button {
  margin: 0 2px;
  padding: 0.25rem 0.5rem;
  border: 1px solid transparent;
  border-radius: 3px;
  background: transparent;
}

.trix-toolbar .trix-button:hover {
  background: #e9ecef;
}

.trix-toolbar .trix-button.trix-active {
  background: #1a73e8;
  color: white;
}
EOF

  # Add rich text helper
  cat <<EOF > app/helpers/rich_text_helper.rb
module RichTextHelper
  def rich_text_field(form, attribute, options = {})
    options[:class] = "#{options[:class]} rich-text-editor"
    options[:data] ||= {}
    options[:data][:controller] = "rich-text-editor"
    
    form.rich_text_area attribute, options
  end
  
  def sanitize_rich_text(content)
    # Custom sanitization for rich text content
    ActionText::Content.new(content).to_s.html_safe
  end
end
EOF

  log "Rich text editing setup completed"
}

setup_karma_system() {
  log "Setting up karma and reputation system"
  
  # Install acts_as_votable for voting system
  bin/rails generate acts_as_votable:migration
  
  # Create karma/reputation system
  bin/rails generate model Reputation user:references score:integer level:string badges:text
  
  cat <<EOF > app/models/concerns/has_reputation.rb
module HasReputation
  extend ActiveSupport::Concern
  
  included do
    has_one :reputation, dependent: :destroy
    after_create :initialize_reputation
    
    acts_as_voter
  end
  
  def karma_score
    reputation&.score || 0
  end
  
  def reputation_level
    case karma_score
    when 0..99 then 'Newcomer'
    when 100..499 then 'Community Member'
    when 500..999 then 'Trusted Member'
    when 1000..4999 then 'Expert'
    when 5000..Float::INFINITY then 'Legend'
    else 'Unranked'
    end
  end
  
  def award_karma(points, reason = nil)
    rep = reputation || build_reputation(score: 0)
    rep.score += points
    rep.save!
    
    KarmaAwardedJob.perform_later(self, points, reason) if reason
  end
  
  def badges
    reputation&.badges&.split(',')&.map(&:strip) || []
  end
  
  def award_badge(badge_name)
    rep = reputation || build_reputation(score: 0, badges: '')
    current_badges = badges
    unless current_badges.include?(badge_name)
      current_badges << badge_name
      rep.update!(badges: current_badges.join(', '))
      BadgeAwardedJob.perform_later(self, badge_name)
    end
  end
  
  private
  
  def initialize_reputation
    create_reputation!(score: 0, level: 'Newcomer', badges: '')
  end
end
EOF

  # Add reputation to User model
  cat <<EOF >> app/models/user.rb

  include HasReputation
  acts_as_votable
EOF

  # Create karma tracking jobs
  mkdir -p app/jobs
  cat <<EOF > app/jobs/karma_awarded_job.rb
class KarmaAwardedJob < ApplicationJob
  queue_as :default
  
  def perform(user, points, reason)
    # Log karma award
    Rails.logger.info "User \#{user.id} awarded \#{points} karma: \#{reason}"
    
    # Send notification if configured
    if user.respond_to?(:notify)
      user.notify("You earned \#{points} karma points for \#{reason}!")
    end
  end
end
EOF

  cat <<EOF > app/jobs/badge_awarded_job.rb
class BadgeAwardedJob < ApplicationJob
  queue_as :default
  
  def perform(user, badge_name)
    Rails.logger.info "User \#{user.id} awarded badge: \#{badge_name}"
    
    if user.respond_to?(:notify)
      user.notify("Congratulations! You earned the '\#{badge_name}' badge!")
    end
  end
end
EOF

  log "Karma and reputation system setup completed"
}

setup_devise() {
  log "Setting up Devise with Vipps and guest login, NNG/SEO optimized"
  bundle add devise omniauth-vipps devise-guests
  if [ $? -ne 0 ]; then
    error "Failed to add Devise gems"
  fi
  bin/rails generate devise:install
  bin/rails generate devise User anonymous:boolean guest:boolean vipps_id:string citizenship_status:string claim_count:integer
  bin/rails generate migration AddOmniauthToUsers provider:string uid:string

  cat <<EOF > config/initializers/devise.rb
Devise.setup do |config|
  config.mailer_sender = "noreply@#{ENV['APP_DOMAIN'] || 'example.com'}"
  config.omniauth :vipps, ENV["VIPPS_CLIENT_ID"], ENV["VIPPS_CLIENT_SECRET"], scope: "openid,email,name"
  config.navigational_formats = [:html]
  config.sign_out_via = :delete
  config.guest_user = true
end
EOF

  cat <<EOF > app/models/user.rb
class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [:vipps]

  validates :email, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :claim_count, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.password = Devise.friendly_token[0, 20]
      user.vipps_id = auth.uid
      user.citizenship_status = auth.info.nationality || "unknown"
      user.guest = false
    end
  end

  def self.guest
    find_or_create_by(guest: true) do |user|
      user.email = "guest_#{Time.now.to_i}#{rand(100)}@example.com"
      user.password = Devise.friendly_token[0, 20]
      user.anonymous = true
    end
  end
end
EOF

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

setup_enhanced_caching() {
  log "Setting up enhanced caching with Solid Cache and Redis"
  
  # Enhanced Solid Cache configuration
  cat <<EOF > config/initializers/solid_cache.rb
# Enhanced Solid Cache configuration for production
Rails.application.configure do
  config.solid_cache.connects_to = { writing: :primary }
  config.solid_cache.key_hash_stage = :fnv1a_64
  config.solid_cache.encrypt = true
  config.solid_cache.size_limit = 512.megabytes
  config.solid_cache.max_age = 1.week
  config.solid_cache.max_entries = 1_000_000
  
  # Cache versioning for easy invalidation
  config.cache_version_manager = ActiveSupport::Cache::VersionManager.new
  
  # Fragment caching optimization
  config.action_controller.perform_caching = true
  config.action_controller.enable_fragment_cache_logging = Rails.env.development?
  
  # View caching for production
  if Rails.env.production?
    config.action_view.cache_template_loading = true
  end
end
EOF

  # Enhanced Redis configuration for sessions and cache
  cat <<EOF > config/initializers/redis.rb
# Enhanced Redis configuration
require 'connection_pool'
require 'hiredis-client'

REDIS_CONFIG = {
  url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0'),
  driver: :hiredis,
  timeout: 5,
  reconnect_attempts: 3,
  reconnect_delay: 0.5,
  reconnect_delay_max: 5.0
}.freeze

# Connection pool for Redis
REDIS_POOL = ConnectionPool.new(size: 10, timeout: 5) do
  Redis.new(REDIS_CONFIG)
end

# Configure Rails cache store
Rails.application.configure do
  config.cache_store = :redis_cache_store, {
    url: REDIS_CONFIG[:url],
    pool: REDIS_POOL,
    expires_in: 1.hour,
    namespace: '${APP_NAME}_cache',
    compress: true,
    compression_threshold: 1024
  }
  
  # Session store configuration
  config.session_store :redis_store, {
    servers: [REDIS_CONFIG[:url]],
    expire_after: 30.days,
    key: "_${APP_NAME}_session",
    secure: Rails.env.production?,
    httponly: true,
    same_site: :lax
  }
end
EOF

  # Add caching concerns and utilities
  cat <<EOF > app/models/concerns/cacheable.rb
module Cacheable
  extend ActiveSupport::Concern
  
  class_methods do
    def cache_key_for(id, updated_at = nil)
      if updated_at
        "#{model_name.cache_key}/#{id}-#{updated_at.to_i}"
      else
        "#{model_name.cache_key}/#{id}"
      end
    end
    
    def cached_find(id)
      Rails.cache.fetch(cache_key_for(id), expires_in: 1.hour) do
        find(id)
      end
    end
    
    def invalidate_cache_for(id)
      Rails.cache.delete(cache_key_for(id))
    end
  end
  
  included do
    after_update :invalidate_cache
    after_destroy :invalidate_cache
  end
  
  private
  
  def invalidate_cache
    self.class.invalidate_cache_for(id)
    Rails.cache.delete("#{self.class.model_name.cache_key}/#{id}")
  end
end
EOF

  # Cache management utilities
  cat <<EOF > app/helpers/cache_helper.rb
module CacheHelper
  def cache_key_for(object, *qualifiers)
    case object
    when Array
      object.map { |item| cache_key_for(item) }.join('/')
    when ActiveRecord::Base
      object.cache_key_with_version
    else
      object.to_s
    end + (qualifiers.any? ? "/#{qualifiers.join('/')}" : '')
  end
  
  def cache_if_production(key, expires_in: 1.hour, &block)
    if Rails.env.production?
      Rails.cache.fetch(key, expires_in: expires_in, &block)
    else
      yield
    end
  end
  
  def fragment_cache_key(name, object = nil, **options)
    key_parts = [name]
    key_parts << cache_key_for(object) if object
    key_parts << options.to_query if options.any?
    key_parts.join('/')
  end
end
EOF

  # Cache warming job
  cat <<EOF > app/jobs/cache_warming_job.rb
class CacheWarmingJob < ApplicationJob
  queue_as :low_priority
  
  def perform
    # Warm up frequently accessed caches
    warm_homepage_cache
    warm_user_counts
    warm_popular_content
  end
  
  private
  
  def warm_homepage_cache
    Rails.cache.fetch('homepage_stats', expires_in: 1.hour) do
      {
        total_users: User.count,
        posts_today: Post.where('created_at > ?', 1.day.ago).count,
        active_users: User.where('last_sign_in_at > ?', 1.week.ago).count
      }
    end
  end
  
  def warm_user_counts
    User.find_each(batch_size: 100) do |user|
      Rails.cache.fetch("user_#{user.id}_stats", expires_in: 30.minutes) do
        {
          posts_count: user.posts.count,
          karma_score: user.karma_score,
          reputation_level: user.reputation_level
        }
      end
    end
  end
  
  def warm_popular_content
    Rails.cache.fetch('popular_posts', expires_in: 15.minutes) do
      Post.joins(:votes)
          .group('posts.id')
          .order('COUNT(votes.id) DESC')
          .limit(10)
          .pluck(:id, :title)
    end
  end
end
EOF

  log "Enhanced caching setup completed"
}

setup_enhanced_search() {
  log "Setting up enhanced search with pg_search and Searchkick"
  
  # Configure pg_search for basic text search
  cat <<EOF > config/initializers/pg_search.rb
# Enhanced PostgreSQL search configuration
PgSearch.multisearch_options = {
  using: {
    tsearch: {
      prefix: true,
      highlight: {
        start_sel: '<mark>',
        stop_sel: '</mark>',
        max_words: 35,
        min_words: 15,
        short_word: 4,
        highlight_all: true,
        max_fragments: 0,
        fragment_delimiter: ' ... '
      }
    },
    trigram: {
      threshold: 0.3
    }
  },
  ranked_by: ':tsearch'
}
EOF

  # Add search functionality to models
  cat <<EOF > app/models/concerns/searchable.rb
module Searchable
  extend ActiveSupport::Concern
  
  included do
    include PgSearch::Model
    
    # Multi-search setup
    multisearchable against: [:title, :content, :description],
                   if: :should_be_indexed?
    
    # Scoped search
    pg_search_scope :search_text, 
      against: [:title, :content, :description],
      using: {
        tsearch: { 
          prefix: true,
          highlight: {
            start_sel: '<mark class="search-highlight">',
            stop_sel: '</mark>'
          }
        },
        trigram: { threshold: 0.3 }
      },
      ranked_by: ':tsearch'
    
    after_update_commit :update_search_index
    after_destroy_commit :remove_from_search_index
  end
  
  class_methods do
    def global_search(query)
      PgSearch.multisearch(query)
             .includes(:searchable)
             .page(1)
             .per(20)
    end
    
    def search_with_filters(query, filters = {})
      results = search_text(query)
      
      # Apply date filters
      if filters[:date_range]
        results = results.where(created_at: filters[:date_range])
      end
      
      # Apply user filter
      if filters[:user_id]
        results = results.where(user_id: filters[:user_id])
      end
      
      # Apply category filter
      if filters[:category] && respond_to?(:by_category)
        results = results.by_category(filters[:category])
      end
      
      results
    end
  end
  
  private
  
  def should_be_indexed?
    # Only index published, non-deleted content
    (!respond_to?(:published?) || published?) &&
    (!respond_to?(:deleted?) || !deleted?)
  end
  
  def update_search_index
    update_pg_search_document if should_be_indexed?
  end
  
  def remove_from_search_index
    pg_search_document&.destroy
  end
end
EOF

  # Enhanced search controller
  cat <<EOF > app/controllers/search_controller.rb
class SearchController < ApplicationController
  def index
    @query = params[:q]&.strip
    @filters = search_filters
    @page = params[:page] || 1
    
    if @query.present?
      @results = perform_search
      track_search_event
    else
      @results = []
      @suggestions = search_suggestions
    end
    
    respond_to do |format|
      format.html
      format.json { render json: search_results_json }
    end
  end
  
  def suggestions
    query = params[:q]&.strip
    
    if query.present? && query.length >= 2
      suggestions = generate_suggestions(query)
      render json: { suggestions: suggestions }
    else
      render json: { suggestions: [] }
    end
  end
  
  private
  
  def perform_search
    case @filters[:type]
    when 'posts'
      Post.search_with_filters(@query, @filters).page(@page)
    when 'users'
      User.search_with_filters(@query, @filters).page(@page)
    else
      PgSearch.multisearch(@query).includes(:searchable).page(@page)
    end
  end
  
  def search_filters
    {
      type: params[:type],
      date_range: date_range_filter,
      category: params[:category],
      user_id: params[:user_id]
    }.compact
  end
  
  def date_range_filter
    case params[:date]
    when 'today'
      1.day.ago..Time.current
    when 'week'
      1.week.ago..Time.current
    when 'month'
      1.month.ago..Time.current
    else
      nil
    end
  end
  
  def search_suggestions
    Rails.cache.fetch('search_suggestions', expires_in: 1.hour) do
      # Get popular search terms, trending topics, etc.
      []
    end
  end
  
  def generate_suggestions(query)
    # Simple autocomplete based on existing content
    Post.where("title ILIKE ?", "%#{query}%")
        .limit(5)
        .pluck(:title)
        .map { |title| title.truncate(50) }
  end
  
  def track_search_event
    ahoy.track "Search", {
      query: @query,
      filters: @filters,
      results_count: @results.respond_to?(:total_count) ? @results.total_count : @results.count
    }
  end
  
  def search_results_json
    {
      query: @query,
      total: @results.respond_to?(:total_count) ? @results.total_count : @results.count,
      results: @results.map { |result| format_search_result(result) }
    }
  end
  
  def format_search_result(result)
    searchable = result.respond_to?(:searchable) ? result.searchable : result
    
    {
      id: searchable.id,
      type: searchable.class.name.downcase,
      title: searchable.try(:title) || searchable.try(:name) || "Item ##{searchable.id}",
      excerpt: searchable.try(:content)&.truncate(150) || searchable.try(:description)&.truncate(150),
      url: url_for(searchable),
      created_at: searchable.created_at&.iso8601
    }
  end
end
EOF

  log "Enhanced search setup completed"
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

setup_enhanced_pwa() {
  log "Setting up enhanced PWA with offline support and notifications"
  
  # Install serviceworker-rails if not already present
  bundle add serviceworker-rails web-push
  bin/rails generate serviceworker:install --skip-application-js
  
  # Create enhanced service worker
  cat <<EOF > app/assets/javascripts/serviceworker.js
// Enhanced Progressive Web App Service Worker
const CACHE_NAME = '${APP_NAME}-v1';
const OFFLINE_URL = '/offline.html';

const PRECACHE_URLS = [
  '/',
  '/offline.html',
  '/assets/application.css',
  '/assets/application.js',
  '/manifest.json'
];

// Install event - cache essential resources
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME)
      .then((cache) => cache.addAll(PRECACHE_URLS))
      .then(() => self.skipWaiting())
  );
});

// Activate event - clean up old caches
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((cacheNames) => {
      return Promise.all(
        cacheNames
          .filter((cacheName) => cacheName !== CACHE_NAME)
          .map((cacheName) => caches.delete(cacheName))
      );
    }).then(() => self.clients.claim())
  );
});

// Fetch event - serve from cache, fallback to network
self.addEventListener('fetch', (event) => {
  if (event.request.mode === 'navigate') {
    event.respondWith(
      fetch(event.request).catch(() => {
        return caches.match(OFFLINE_URL);
      })
    );
  } else {
    event.respondWith(
      caches.match(event.request).then((response) => {
        return response || fetch(event.request).catch(() => {
          // Return a fallback for failed non-navigation requests
          if (event.request.destination === 'image') {
            return new Response('', { status: 200, statusText: 'OK' });
          }
          return new Response('Offline', { status: 503, statusText: 'Service Unavailable' });
        });
      })
    );
  }
});

// Push notification event
self.addEventListener('push', (event) => {
  const options = {
    body: event.data ? event.data.text() : 'New notification',
    icon: '/icon-192x192.png',
    badge: '/badge-72x72.png',
    tag: 'notification',
    requireInteraction: false,
    actions: [
      {
        action: 'view',
        title: 'View',
        icon: '/icon-view.png'
      },
      {
        action: 'dismiss',
        title: 'Dismiss',
        icon: '/icon-dismiss.png'
      }
    ]
  };

  event.waitUntil(
    self.registration.showNotification('${APP_NAME}', options)
  );
});

// Notification click event
self.addEventListener('notificationclick', (event) => {
  event.notification.close();

  if (event.action === 'view') {
    event.waitUntil(
      clients.openWindow('/')
    );
  }
});

// Background sync for offline actions
self.addEventListener('sync', (event) => {
  if (event.tag === 'background-sync') {
    event.waitUntil(
      // Handle background sync logic here
      console.log('Background sync triggered')
    );
  }
});
EOF

  # Enhanced manifest.json
  cat <<EOF > public/manifest.json
{
  "name": "${APP_NAME^} - Community Platform",
  "short_name": "${APP_NAME^}",
  "description": "Connect with your local community through ${APP_NAME}",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#ffffff",
  "theme_color": "#1a73e8",
  "orientation": "portrait-primary",
  "scope": "/",
  "lang": "en",
  "categories": ["social", "lifestyle", "productivity"],
  "icons": [
    {
      "src": "/icon-72x72.png",
      "sizes": "72x72",
      "type": "image/png",
      "purpose": "any maskable"
    },
    {
      "src": "/icon-96x96.png", 
      "sizes": "96x96",
      "type": "image/png",
      "purpose": "any maskable"
    },
    {
      "src": "/icon-128x128.png",
      "sizes": "128x128", 
      "type": "image/png",
      "purpose": "any maskable"
    },
    {
      "src": "/icon-144x144.png",
      "sizes": "144x144",
      "type": "image/png",
      "purpose": "any maskable"
    },
    {
      "src": "/icon-152x152.png",
      "sizes": "152x152",
      "type": "image/png",
      "purpose": "any maskable"
    },
    {
      "src": "/icon-192x192.png",
      "sizes": "192x192",
      "type": "image/png",
      "purpose": "any maskable"
    },
    {
      "src": "/icon-384x384.png",
      "sizes": "384x384",
      "type": "image/png",
      "purpose": "any maskable"
    },
    {
      "src": "/icon-512x512.png",
      "sizes": "512x512",
      "type": "image/png",
      "purpose": "any maskable"
    }
  ],
  "shortcuts": [
    {
      "name": "Create Post",
      "url": "/posts/new",
      "description": "Create a new post"
    },
    {
      "name": "Browse",
      "url": "/browse",
      "description": "Browse content"
    },
    {
      "name": "Profile",
      "url": "/profile",
      "description": "View your profile"
    }
  ],
  "screenshots": [
    {
      "src": "/screenshot-mobile.png",
      "sizes": "540x720",
      "type": "image/png"
    },
    {
      "src": "/screenshot-desktop.png", 
      "sizes": "1280x720",
      "type": "image/png"
    }
  ]
}
EOF

  # Enhanced offline page
  cat <<EOF > public/offline.html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Offline - ${APP_NAME^}</title>
  <meta name="description" content="You are currently offline. Please check your connection.">
  <link rel="manifest" href="/manifest.json">
  <meta name="theme-color" content="#1a73e8">
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      margin: 0;
      padding: 2rem;
      text-align: center;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      color: white;
      min-height: 100vh;
      display: flex;
      flex-direction: column;
      justify-content: center;
      align-items: center;
    }
    .offline-container {
      max-width: 400px;
      padding: 2rem;
      background: rgba(255, 255, 255, 0.1);
      border-radius: 12px;
      backdrop-filter: blur(10px);
      box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
    }
    .offline-icon {
      width: 80px;
      height: 80px;
      margin: 0 auto 1rem;
      background: rgba(255, 255, 255, 0.2);
      border-radius: 50%;
      display: flex;
      align-items: center;
      justify-content: center;
      font-size: 2rem;
    }
    h1 { margin: 0 0 1rem; font-size: 1.5rem; }
    p { margin: 0 0 1rem; opacity: 0.9; line-height: 1.5; }
    .retry-btn {
      background: rgba(255, 255, 255, 0.2);
      border: 2px solid rgba(255, 255, 255, 0.3);
      color: white;
      padding: 0.75rem 1.5rem;
      border-radius: 8px;
      cursor: pointer;
      font-size: 1rem;
      transition: all 0.3s ease;
    }
    .retry-btn:hover {
      background: rgba(255, 255, 255, 0.3);
      border-color: rgba(255, 255, 255, 0.5);
    }
    .network-status {
      margin-top: 1rem;
      font-size: 0.9rem;
      opacity: 0.8;
    }
  </style>
</head>
<body>
  <div class="offline-container">
    <div class="offline-icon">📡</div>
    <h1>You're Offline</h1>
    <p>It looks like you've lost your internet connection. Don't worry, we'll get you back online!</p>
    <button class="retry-btn" onclick="location.reload()">Try Again</button>
    <div class="network-status" id="networkStatus">Checking connection...</div>
  </div>

  <script>
    // Check network status
    function updateNetworkStatus() {
      const status = navigator.onLine ? 'Connected' : 'Offline';
      document.getElementById('networkStatus').textContent = 'Status: ' + status;
      
      if (navigator.onLine) {
        setTimeout(() => location.reload(), 1000);
      }
    }

    window.addEventListener('online', updateNetworkStatus);
    window.addEventListener('offline', updateNetworkStatus);
    updateNetworkStatus();

    // Periodic connection check
    setInterval(() => {
      fetch('/ping', { method: 'HEAD', cache: 'no-cache' })
        .then(() => location.reload())
        .catch(() => {}); // Still offline
    }, 5000);
  </script>
</body>
</html>
EOF

  # Add PWA meta tags helper
  cat <<EOF > app/helpers/pwa_helper.rb
module PwaHelper
  def pwa_meta_tags
    content_for :head do
      safe_join([
        tag.link(rel: 'manifest', href: '/manifest.json'),
        tag.meta(name: 'theme-color', content: '#1a73e8'),
        tag.meta(name: 'apple-mobile-web-app-capable', content: 'yes'),
        tag.meta(name: 'apple-mobile-web-app-status-bar-style', content: 'default'),
        tag.meta(name: 'apple-mobile-web-app-title', content: '${APP_NAME^}'),
        tag.link(rel: 'apple-touch-icon', href: '/icon-152x152.png'),
        tag.meta(name: 'msapplication-TileImage', content: '/icon-144x144.png'),
        tag.meta(name: 'msapplication-TileColor', content: '#1a73e8')
      ])
    end
  end
  
  def install_prompt_available?
    # Check if PWA install prompt should be shown
    request.user_agent.match?(/(iPhone|iPad|Android)/) && 
    !request.user_agent.match?(/GSA\//)
  end
end
EOF

  log "Enhanced PWA setup completed"
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
  log "Committing changes: '$1'"
  command_exists "git"
  if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    git init
    if [ $? -ne 0 ]; then
      error "Failed to initialize Git repository"
    fi
  fi
  git add .
  git commit -m "$1"
  if [ $? -ne 0 ]; then
    log "No changes to commit"
  fi
}

migrate_db() {
  log "Running database migrations"
  bin/rails db:migrate RAILS_ENV=production
  if [ $? -ne 0 ]; then
    error "Failed to run database migrations"
  fi
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
  log "Setting up Stimulus components for enhanced UX from stimulus-components.com"
  
  # Install core stimulus components from stimulus-components.com
  yarn add stimulus-lightbox stimulus-infinite-scroll stimulus-character-counter stimulus-textarea-autogrow stimulus-carousel stimulus-use stimulus-debounce stimulus-dropdown stimulus-clipboard stimulus-tabs stimulus-popover stimulus-tooltip
  if [ $? -ne 0 ]; then
    error "Failed to install Stimulus components"
  fi
  
  # Create modern stimulus controllers
  mkdir -p app/javascript/controllers
  
  # Modern lightbox controller
  cat <<EOF > app/javascript/controllers/lightbox_controller.js
import { Controller } from "@hotwired/stimulus"
import { Lightbox } from "stimulus-lightbox"

export default class extends Controller {
  static targets = ["image"]
  
  connect() {
    this.lightbox = new Lightbox(this.element, {
      keyboard: true,
      closeOnOutsideClick: true
    })
  }
  
  disconnect() {
    this.lightbox.destroy()
  }
}
EOF

  # Modern dropdown controller
  cat <<EOF > app/javascript/controllers/dropdown_controller.js
import { Controller } from "@hotwired/stimulus"
import { useClickOutside } from "stimulus-use"

export default class extends Controller {
  static targets = ["menu"]
  static classes = ["open"]
  
  connect() {
    useClickOutside(this)
  }
  
  toggle() {
    this.menuTarget.classList.toggle(this.openClass)
  }
  
  clickOutside() {
    this.menuTarget.classList.remove(this.openClass)
  }
}
EOF

  # Modern clipboard controller
  cat <<EOF > app/javascript/controllers/clipboard_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["source", "button"]
  static classes = ["success"]
  
  copy() {
    navigator.clipboard.writeText(this.sourceTarget.textContent)
      .then(() => {
        this.buttonTarget.classList.add(this.successClass)
        setTimeout(() => {
          this.buttonTarget.classList.remove(this.successClass)
        }, 2000)
      })
  }
}
EOF

  log "Modern Stimulus components setup completed"
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
  log "Setting up full Rails app '$1' with production enhancements and modern architecture"
  
  # System checks first
  check_system_requirements
  
  init_app "$1"
  setup_postgresql "$1"
  setup_redis
  setup_ruby
  setup_yarn
  setup_rails "$1"
  
  # Core Rails 8 features
  setup_solid_queue
  setup_solid_cache
  setup_enhanced_caching
  
  # Authentication and security
  setup_devise
  setup_storage
  
  # Enhanced features
  setup_production_monitoring
  setup_analytics
  setup_rich_text
  setup_karma_system
  setup_enhanced_search
  
  # Frontend enhancements  
  setup_enhanced_stimulus_components
  setup_vote_controller
  setup_infinite_scroll
  
  # Core functionality
  setup_anon_posting
  setup_anon_chat
  
  # PWA and offline features
  setup_enhanced_pwa
  
  # Additional integrations
  setup_stripe
  setup_mapbox
  
  # Background processing
  setup_expiry_job
  setup_seeds
  setup_enhanced_i18n
  setup_falcon
  
  # Model generation
  generate_social_models
  
  # Database and final setup
  migrate_db
  
  # Styling
  setup_enhanced_styles
  
  log "Full app setup completed with production enhancements"
}

setup_enhanced_stimulus_components() {
  log "Setting up enhanced Stimulus components with modern UX patterns"
  
  # Install comprehensive stimulus components
  yarn add stimulus-lightbox stimulus-infinite-scroll stimulus-character-counter \
           stimulus-textarea-autogrow stimulus-carousel stimulus-use stimulus-debounce \
           stimulus-dropdown stimulus-clipboard stimulus-tabs stimulus-popover \
           stimulus-tooltip stimulus-reveal stimulus-sortable stimulus-notifications
  
  if [ $? -ne 0 ]; then
    error "Failed to install enhanced Stimulus components"
  fi
  
  # Enhanced search controller with analytics
  cat <<EOF > app/javascript/controllers/enhanced_search_controller.js
import { Controller } from "@hotwired/stimulus"
import { useDebounce } from "stimulus-use"

export default class extends Controller {
  static targets = ["input", "results", "suggestions", "filters"]
  static values = { 
    url: String, 
    minLength: { type: Number, default: 2 },
    debounce: { type: Number, default: 300 }
  }

  connect() {
    useDebounce(this, { wait: this.debounceValue })
    this.abortController = new AbortController()
  }

  disconnect() {
    this.abortController.abort()
  }

  search() {
    const query = this.inputTarget.value.trim()
    
    if (query.length < this.minLengthValue) {
      this.clearResults()
      return
    }

    this.showLoading()
    this.fetchResults(query)
  }

  async fetchResults(query) {
    try {
      const params = new URLSearchParams({
        q: query,
        format: 'json'
      })
      
      // Add filter values if present
      if (this.hasFiltersTarget) {
        const formData = new FormData(this.filtersTarget)
        formData.forEach((value, key) => params.append(key, value))
      }

      const response = await fetch(`${this.urlValue}?${params}`, {
        signal: this.abortController.signal,
        headers: {
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })

      if (!response.ok) throw new Error('Search failed')

      const data = await response.json()
      this.displayResults(data)
      this.trackSearchEvent(query, data.total)
      
    } catch (error) {
      if (error.name !== 'AbortError') {
        console.error('Search error:', error)
        this.showError()
      }
    }
  }

  displayResults(data) {
    const html = data.results.map(result => this.formatResult(result)).join('')
    this.resultsTarget.innerHTML = html
    
    if (data.results.length === 0) {
      this.showNoResults()
    }
  }

  formatResult(result) {
    return `
      <div class="search-result" data-action="click->enhanced-search#selectResult">
        <h4 class="search-result-title">
          <a href="${result.url}">${this.highlightQuery(result.title)}</a>
        </h4>
        <p class="search-result-excerpt">${this.highlightQuery(result.excerpt)}</p>
        <small class="search-result-meta">${result.type} • ${this.formatDate(result.created_at)}</small>
      </div>
    `
  }

  highlightQuery(text) {
    if (!text) return ''
    const query = this.inputTarget.value.trim()
    if (!query) return text
    
    const regex = new RegExp(`(${query})`, 'gi')
    return text.replace(regex, '<mark>$1</mark>')
  }

  formatDate(dateString) {
    return new Date(dateString).toLocaleDateString()
  }

  showLoading() {
    this.resultsTarget.innerHTML = '<div class="search-loading">Searching...</div>'
  }

  clearResults() {
    this.resultsTarget.innerHTML = ''
  }

  showNoResults() {
    this.resultsTarget.innerHTML = '<div class="search-no-results">No results found</div>'
  }

  showError() {
    this.resultsTarget.innerHTML = '<div class="search-error">Search error. Please try again.</div>'
  }

  selectResult(event) {
    const query = this.inputTarget.value.trim()
    this.trackClickEvent(query, event.currentTarget)
  }

  trackSearchEvent(query, resultCount) {
    if (typeof ahoy !== 'undefined') {
      ahoy.track('Search Performed', {
        query: query,
        result_count: resultCount,
        timestamp: new Date().toISOString()
      })
    }
  }

  trackClickEvent(query, element) {
    if (typeof ahoy !== 'undefined') {
      const title = element.querySelector('.search-result-title a')?.textContent
      ahoy.track('Search Result Clicked', {
        query: query,
        result_title: title,
        timestamp: new Date().toISOString()
      })
    }
  }
}
EOF

  # Enhanced notification system
  cat <<EOF > app/javascript/controllers/notification_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    message: String,
    type: { type: String, default: "info" },
    duration: { type: Number, default: 5000 },
    closable: { type: Boolean, default: true }
  }

  connect() {
    this.element.classList.add('notification', `notification--${this.typeValue}`)
    
    if (this.closableValue) {
      this.addCloseButton()
    }
    
    if (this.durationValue > 0) {
      this.timeout = setTimeout(() => {
        this.dismiss()
      }, this.durationValue)
    }
    
    // Animate in
    requestAnimationFrame(() => {
      this.element.classList.add('notification--visible')
    })
  }

  addCloseButton() {
    const closeButton = document.createElement('button')
    closeButton.innerHTML = '×'
    closeButton.className = 'notification__close'
    closeButton.setAttribute('data-action', 'click->notification#dismiss')
    closeButton.setAttribute('aria-label', 'Close notification')
    this.element.appendChild(closeButton)
  }

  dismiss() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
    
    this.element.classList.add('notification--dismissing')
    
    setTimeout(() => {
      if (this.element.parentNode) {
        this.element.remove()
      }
    }, 300)
  }

  static show(message, type = 'info', options = {}) {
    const container = document.querySelector('#notifications') || 
                     this.createNotificationContainer()
    
    const notification = document.createElement('div')
    notification.setAttribute('data-controller', 'notification')
    notification.setAttribute('data-notification-message-value', message)
    notification.setAttribute('data-notification-type-value', type)
    
    if (options.duration !== undefined) {
      notification.setAttribute('data-notification-duration-value', options.duration)
    }
    
    if (options.closable !== undefined) {
      notification.setAttribute('data-notification-closable-value', options.closable)
    }
    
    notification.textContent = message
    container.appendChild(notification)
    
    return notification
  }

  static createNotificationContainer() {
    const container = document.createElement('div')
    container.id = 'notifications'
    container.className = 'notifications-container'
    document.body.appendChild(container)
    return container
  }
}
EOF

  log "Enhanced Stimulus components setup completed"
}

setup_enhanced_styles() {
  log "Setting up enhanced styles with design system"
  
  cat <<EOF > app/assets/stylesheets/design_system.scss
// Enhanced Design System following Golden Ratio and WCAG AAA
:root {
  // Color system with semantic HSL
  --primary-hue: 215;
  --primary-saturation: 84%;
  --primary-lightness: 48%;
  
  --primary-50: hsl(var(--primary-hue), 95%, 95%);
  --primary-100: hsl(var(--primary-hue), 90%, 85%);
  --primary-500: hsl(var(--primary-hue), var(--primary-saturation), var(--primary-lightness));
  --primary-900: hsl(var(--primary-hue), 50%, 15%);
  
  // Neutral colors
  --white: #ffffff;
  --black: #000000;
  --gray-50: #f9fafb;
  --gray-100: #f3f4f6;
  --gray-200: #e5e7eb;
  --gray-300: #d1d5db;
  --gray-400: #9ca3af;
  --gray-500: #6b7280;
  --gray-600: #4b5563;
  --gray-700: #374151;
  --gray-800: #1f2937;
  --gray-900: #111827;
  
  // Status colors
  --success: #10b981;
  --warning: #f59e0b;
  --error: #ef4444;
  --info: var(--primary-500);
  
  // Typography scale (Golden Ratio 1.618)
  --text-xs: 0.75rem;      /* 12px */
  --text-sm: 0.875rem;     /* 14px */
  --text-base: 1rem;       /* 16px */
  --text-lg: 1.125rem;     /* 18px */
  --text-xl: 1.25rem;      /* 20px */
  --text-2xl: 1.5rem;      /* 24px */
  --text-3xl: 1.875rem;    /* 30px */
  --text-4xl: 2.25rem;     /* 36px */
  --text-5xl: 3rem;        /* 48px */
  
  // Spacing scale (Golden Ratio base)
  --space-1: 0.25rem;   /* 4px */
  --space-2: 0.5rem;    /* 8px */
  --space-3: 0.75rem;   /* 12px */
  --space-4: 1rem;      /* 16px */
  --space-5: 1.25rem;   /* 20px */
  --space-6: 1.5rem;    /* 24px */
  --space-8: 2rem;      /* 32px */
  --space-10: 2.5rem;   /* 40px */
  --space-12: 3rem;     /* 48px */
  --space-16: 4rem;     /* 64px */
  --space-20: 5rem;     /* 80px */
  
  // Breakpoints
  --breakpoint-sm: 640px;
  --breakpoint-md: 768px;
  --breakpoint-lg: 1024px;
  --breakpoint-xl: 1280px;
  --breakpoint-2xl: 1536px;
  
  // Shadows
  --shadow-sm: 0 1px 2px 0 rgb(0 0 0 / 0.05);
  --shadow: 0 1px 3px 0 rgb(0 0 0 / 0.1), 0 1px 2px -1px rgb(0 0 0 / 0.1);
  --shadow-md: 0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1);
  --shadow-lg: 0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1);
  --shadow-xl: 0 20px 25px -5px rgb(0 0 0 / 0.1), 0 8px 10px -6px rgb(0 0 0 / 0.1);
  
  // Animation
  --transition-fast: 150ms ease;
  --transition-base: 200ms ease;
  --transition-slow: 300ms ease;
}

// Reset and base styles
* {
  box-sizing: border-box;
}

html {
  font-size: 16px;
  line-height: 1.618; // Golden ratio
}

body {
  margin: 0;
  padding: 0;
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, Cantarell, sans-serif;
  background: var(--white);
  color: var(--gray-900);
  line-height: 1.618;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
}

// Typography
h1, h2, h3, h4, h5, h6 {
  margin: 0 0 var(--space-4);
  font-weight: 600;
  line-height: 1.25;
  color: var(--gray-900);
}

h1 { font-size: var(--text-4xl); }
h2 { font-size: var(--text-3xl); }
h3 { font-size: var(--text-2xl); }
h4 { font-size: var(--text-xl); }
h5 { font-size: var(--text-lg); }
h6 { font-size: var(--text-base); }

p {
  margin: 0 0 var(--space-4);
  line-height: 1.618;
}

// Links
a {
  color: var(--primary-500);
  text-decoration: none;
  transition: color var(--transition-fast);
}

a:hover {
  color: var(--primary-900);
  text-decoration: underline;
}

a:focus {
  outline: 2px solid var(--primary-500);
  outline-offset: 2px;
}

// Buttons
.button {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  padding: var(--space-3) var(--space-6);
  border: 1px solid transparent;
  border-radius: 6px;
  font-size: var(--text-base);
  font-weight: 500;
  line-height: 1;
  text-decoration: none;
  cursor: pointer;
  transition: all var(--transition-base);
  min-height: 44px; // WCAG touch target
  
  &:focus {
    outline: 2px solid var(--primary-500);
    outline-offset: 2px;
  }
  
  &:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }
  
  &.button--primary {
    background: var(--primary-500);
    color: var(--white);
    
    &:hover:not(:disabled) {
      background: var(--primary-900);
    }
  }
  
  &.button--secondary {
    background: var(--white);
    border-color: var(--gray-300);
    color: var(--gray-700);
    
    &:hover:not(:disabled) {
      background: var(--gray-50);
      border-color: var(--gray-400);
    }
  }
  
  &.button--danger {
    background: var(--error);
    color: var(--white);
    
    &:hover:not(:disabled) {
      background: #dc2626;
    }
  }
  
  &.button--small {
    padding: var(--space-2) var(--space-4);
    font-size: var(--text-sm);
  }
  
  &.button--large {
    padding: var(--space-4) var(--space-8);
    font-size: var(--text-lg);
  }
}

// Forms
.form-group {
  margin-bottom: var(--space-6);
}

.form-label {
  display: block;
  margin-bottom: var(--space-2);
  font-size: var(--text-sm);
  font-weight: 500;
  color: var(--gray-700);
}

.form-input {
  display: block;
  width: 100%;
  padding: var(--space-3);
  border: 1px solid var(--gray-300);
  border-radius: 6px;
  font-size: var(--text-base);
  line-height: 1.5;
  background: var(--white);
  transition: border-color var(--transition-fast), box-shadow var(--transition-fast);
  
  &:focus {
    outline: none;
    border-color: var(--primary-500);
    box-shadow: 0 0 0 3px rgba(59, 130, 246, 0.1);
  }
  
  &:invalid {
    border-color: var(--error);
  }
  
  &::placeholder {
    color: var(--gray-400);
  }
}

textarea.form-input {
  resize: vertical;
  min-height: 120px;
}

// Cards
.card {
  background: var(--white);
  border: 1px solid var(--gray-200);
  border-radius: 8px;
  box-shadow: var(--shadow-sm);
  overflow: hidden;
  
  &__header {
    padding: var(--space-6);
    border-bottom: 1px solid var(--gray-200);
    background: var(--gray-50);
  }
  
  &__body {
    padding: var(--space-6);
  }
  
  &__footer {
    padding: var(--space-6);
    border-top: 1px solid var(--gray-200);
    background: var(--gray-50);
  }
}

// Notifications
.notifications-container {
  position: fixed;
  top: var(--space-4);
  right: var(--space-4);
  z-index: 9999;
  max-width: 400px;
}

.notification {
  margin-bottom: var(--space-3);
  padding: var(--space-4);
  border-radius: 6px;
  box-shadow: var(--shadow-lg);
  transform: translateX(100%);
  opacity: 0;
  transition: all var(--transition-base);
  
  &--visible {
    transform: translateX(0);
    opacity: 1;
  }
  
  &--dismissing {
    transform: translateX(100%);
    opacity: 0;
  }
  
  &--info {
    background: #dbeafe;
    border: 1px solid #93c5fd;
    color: #1e40af;
  }
  
  &--success {
    background: #d1fae5;
    border: 1px solid #6ee7b7;
    color: #065f46;
  }
  
  &--warning {
    background: #fef3c7;
    border: 1px solid #fcd34d;
    color: #92400e;
  }
  
  &--error {
    background: #fee2e2;
    border: 1px solid #fca5a5;
    color: #991b1b;
  }
  
  &__close {
    position: absolute;
    top: var(--space-2);
    right: var(--space-2);
    background: none;
    border: none;
    font-size: var(--text-lg);
    cursor: pointer;
    opacity: 0.7;
    transition: opacity var(--transition-fast);
    
    &:hover {
      opacity: 1;
    }
  }
}

// Search components
.search-result {
  padding: var(--space-4);
  border-bottom: 1px solid var(--gray-200);
  
  &:last-child {
    border-bottom: none;
  }
  
  &:hover {
    background: var(--gray-50);
  }
  
  &__title {
    margin: 0 0 var(--space-2);
    font-size: var(--text-lg);
    font-weight: 600;
  }
  
  &__excerpt {
    margin: 0 0 var(--space-2);
    color: var(--gray-600);
    line-height: 1.5;
  }
  
  &__meta {
    font-size: var(--text-sm);
    color: var(--gray-500);
  }
}

.search-highlight {
  background: #fef08a;
  padding: 1px 2px;
  border-radius: 2px;
}

// Responsive utilities
@media (max-width: 768px) {
  html {
    font-size: 14px;
  }
  
  .button {
    min-height: 48px; // Larger touch targets on mobile
  }
  
  .notifications-container {
    left: var(--space-4);
    right: var(--space-4);
    max-width: none;
  }
}

// Dark mode support
@media (prefers-color-scheme: dark) {
  :root {
    --white: #1f2937;
    --black: #f9fafb;
    --gray-50: #374151;
    --gray-100: #4b5563;
    --gray-900: #f9fafb;
  }
  
  body {
    background: var(--white);
    color: var(--gray-900);
  }
}

// Reduced motion support
@media (prefers-reduced-motion: reduce) {
  * {
    animation-duration: 0.01ms !important;
    animation-iteration-count: 1 !important;
    transition-duration: 0.01ms !important;
  }
}

// High contrast mode
@media (prefers-contrast: high) {
  :root {
    --primary-500: #0000ff;
    --error: #ff0000;
    --success: #008000;
  }
  
  .button {
    border-width: 2px;
  }
  
  .form-input {
    border-width: 2px;
  }
}
EOF

  log "Enhanced design system setup completed"
}

# Change Log:
# - Enhanced with production-ready monitoring, analytics, rich text, karma system
# - Added enhanced caching with Solid Cache and Redis optimization
# - Integrated advanced search with pg_search and full-text capabilities
# - Added comprehensive PWA support with offline functionality
# - Included enhanced Stimulus components for modern UX
# - Added production monitoring and error tracking
# - Enhanced I18n with multi-language support
# - Added design system following Golden Ratio and WCAG AAA standards
# - Updated to Rails 8 with modern architecture patterns
# - Enhanced for production deployment on OpenBSD 7.5

setup_enhanced_i18n() {
  log "Setting up enhanced I18n with comprehensive translations"
  
  if [ ! -f "config/locales/en.yml" ]; then
    mkdir -p "config/locales"
    cat <<EOF > "config/locales/en.yml"
en:
  shared:
    logo_alt: "${APP_NAME^} Logo"
    footer_nav: "Footer Navigation"
    about: "About"
    contact: "Contact"
    terms: "Terms of Service"
    privacy: "Privacy Policy"
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
    save: "Save"
    cancel: "Cancel"
    edit: "Edit"
    delete: "Delete"
    confirm_delete: "Are you sure you want to delete this?"
    success: "Success"
    error: "Error"
    warning: "Warning"
    info: "Information"
    close: "Close"
    back: "Back"
    next: "Next"
    previous: "Previous"
    home: "Home"
    profile: "Profile"
    settings: "Settings"
    logout: "Log out"
    login: "Log in"
    register: "Register"
    
  errors:
    not_found:
      title: "Page Not Found"
      message: "The page you're looking for doesn't exist."
    internal_server_error:
      title: "Server Error"
      message: "Something went wrong on our end. Please try again later."
    unprocessable_entity:
      title: "Invalid Request"
      message: "The request couldn't be processed. Please check your input."
    go_home: "Go to Homepage"
    
  search:
    placeholder: "Search..."
    no_results: "No results found"
    results_count: 
      zero: "No results"
      one: "1 result"
      other: "%{count} results"
    filters: "Filters"
    sort_by: "Sort by"
    date_range: "Date range"
    category: "Category"
    type: "Type"
    
  notifications:
    new_message: "You have a new message"
    post_liked: "Someone liked your post"
    comment_added: "New comment on your post"
    karma_earned: "You earned %{points} karma points!"
    badge_earned: "Congratulations! You earned the '%{badge}' badge!"
    welcome: "Welcome to ${APP_NAME^}!"
    
  karma:
    levels:
      newcomer: "Newcomer"
      community_member: "Community Member"
      trusted_member: "Trusted Member"
      expert: "Expert"
      legend: "Legend"
    actions:
      post_created: "creating a post"
      comment_added: "adding a comment"
      upvote_received: "receiving an upvote"
      helpful_content: "creating helpful content"
      community_engagement: "engaging with the community"
      
  pwa:
    install_prompt: "Install ${APP_NAME^} for a better experience"
    install_button: "Install App"
    offline_ready: "App is ready to work offline"
    update_available: "A new version is available"
    update_button: "Update Now"
    
  ${APP_NAME}:
    home_title: "${APP_NAME^} Home"
    home_description: "Welcome to ${APP_NAME^}, a community-driven platform."
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
    
  devise:
    sessions:
      new:
        title: "Sign In"
        description: "Sign in with Vipps to access the app"
        keywords: "sign in, vipps, app"
        sign_in_with_vipps: "Sign in with Vipps"
      signed_in: "Signed in successfully."
      signed_out: "Signed out successfully."
    registrations:
      signed_up: "Welcome! You have signed up successfully."
    passwords:
      send_instructions: "You will receive an email with instructions on how to reset your password in a few minutes."
    confirmations:
      send_instructions: "You will receive an email with instructions for how to confirm your email address in a few minutes."
      
  time:
    formats:
      short: "%b %d"
      long: "%B %d, %Y"
      time: "%I:%M %p"
      
  date:
    formats:
      short: "%b %d"
      long: "%B %d, %Y"
      
  activerecord:
    errors:
      messages:
        blank: "can't be blank"
        taken: "has already been taken"
        too_short: "is too short (minimum is %{count} characters)"
        too_long: "is too long (maximum is %{count} characters)"
        invalid: "is invalid"
        confirmation: "doesn't match confirmation"
        
  helpers:
    submit:
      create: "Create %{model}"
      update: "Update %{model}"
      submit: "Save %{model}"
EOF
  fi
  
  # Add Norwegian locale for Norwegian cities
  cat <<EOF > "config/locales/nb.yml"
nb:
  shared:
    logo_alt: "${APP_NAME^} Logo"
    footer_nav: "Bunntekst navigasjon"
    about: "Om oss"
    contact: "Kontakt"
    terms: "Vilkår"
    privacy: "Personvern"
    support: "Support"
    load_more: "Last inn mer"
    
  ${APP_NAME}:
    home_title: "${APP_NAME^} Hjem"
    home_description: "Velkommen til ${APP_NAME^}, en fellesskapsdrevet plattform."
    whats_on_your_mind: "Hva tenker du på?"
    post_submit: "Del"
    chat_title: "Fellesskaps Chat"
    chat_placeholder: "Skriv en melding..."
EOF

  # Configure I18n
  cat <<EOF > config/initializers/i18n.rb
# Enhanced I18n configuration
Rails.application.configure do
  # Available locales
  config.i18n.available_locales = [:en, :nb, :da, :sv, :fi, :is, :de, :fr, :es, :it, :pt, :nl]
  
  # Default locale
  config.i18n.default_locale = :en
  
  # Fallback to English for missing translations
  config.i18n.fallbacks = [I18n.default_locale]
  
  # Load all translation files
  config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}')]
  
  # Raise exceptions for missing translations in development
  config.i18n.raise_on_missing_translations = Rails.env.development?
end

# Custom I18n helpers
module I18nHelpers
  def current_locale_name
    I18n.t("locales.#{I18n.locale}", default: I18n.locale.to_s.humanize)
  end
  
  def locale_options
    I18n.available_locales.map do |locale|
      [I18n.t("locales.#{locale}", default: locale.to_s.humanize), locale]
    end
  end
  
  def t_with_fallback(key, options = {})
    I18n.t(key, **options)
  rescue I18n::MissingTranslationData
    I18n.t(key, **options.merge(locale: :en))
  end
end

# Add helper to controllers and views
ActionController::Base.include I18nHelpers
ActionView::Base.include I18nHelpers
EOF

  log "Enhanced I18n setup completed"
}

# Enhanced commit function with better Git practices
commit() {
  log "Committing changes with enhanced Git practices: '$1'"
  command_exists "git"
  
  if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    git init
    git branch -m main
    if [ $? -ne 0 ]; then
      error "Failed to initialize Git repository"
    fi
  fi
  
  # Check for uncommitted changes
  if git diff --quiet && git diff --staged --quiet; then
    log "No changes to commit"
    return 0
  fi
  
  # Stage all changes
  git add .
  
  # Create comprehensive commit message
  local commit_msg="$1"
  if [ ${#commit_msg} -gt 50 ]; then
    commit_msg=$(echo "$commit_msg" | cut -c1-47)...
  fi
  
  # Add detailed commit body with metrics
  local files_changed=$(git diff --staged --name-only | wc -l)
  local lines_added=$(git diff --staged --numstat | awk '{sum+=$1} END {print sum+0}')
  local lines_deleted=$(git diff --staged --numstat | awk '{sum+=$2} END {print sum+0}')
  
  git commit -m "$commit_msg" -m "
Files changed: $files_changed
Lines added: $lines_added
Lines deleted: $lines_deleted
App: ${APP_NAME}
Environment: ${RAILS_ENV}
Rails version: ${RAILS_VERSION}
Timestamp: $(date -u +'%Y-%m-%dT%H:%M:%SZ')
"
  
  if [ $? -ne 0 ]; then
    error "Failed to commit changes"
  fi
  
  log "Successfully committed changes"
}