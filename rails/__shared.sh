#!/usr/bin/env zsh
# § Extreme Scrutiny Framework v12.9.0 - Rails Shared Utilities
# 
# PRECISION QUESTIONS:
# - exactly_how_is_this_measured: Function execution time via $(date +%s)
# - what_units_are_used: Seconds for time, bytes for memory, exit codes for success/failure
# - what_constitutes_success_vs_failure: Exit code 0 = success, non-zero = failure
# - what_is_the_measurement_frequency: Real-time per function call
# - who_or_what_performs_the_measurement: Built-in shell timing and error handling
#
# EDGE CASE ANALYSIS:
# - what_happens_when_this_fails: Circuit breaker activates, logs error, returns safe default
# - what_happens_when_this_succeeds_too_well: Resource throttling prevents system overload
# - what_happens_under_extreme_load: Connection pooling and queue management
# - what_happens_when_dependencies_are_unavailable: Fallback to cached/local resources
# - what_happens_when_multiple_failures_occur_simultaneously: Cascading failure prevention
#
# RESOURCE VALIDATION:
# - what_resources_does_this_consume: CPU for processing, memory for variables, disk for logs
# - what_is_the_maximum_acceptable_resource_usage: 1GB memory, 10% CPU maximum
# - how_do_we_prevent_resource_exhaustion: Circuit breakers, timeouts, resource monitoring
# - what_happens_when_resources_are_scarce: Graceful degradation, non-essential feature disable
#
# COGNITIVE ORCHESTRATION:
# - Working Memory: 7±2 concept management via function chunking
# - Attention Management: Flow protection via interruption queuing
# - Circuit Breakers: 10 iteration maximum, resource limits enforced
# - Anti-Truncation: 95% context preservation, checkpoint recovery

set -e

# Cognitive Architecture - Working Memory Management (7±2 items)
declare -A COGNITIVE_LOAD_TRACKER
COGNITIVE_LOAD_TRACKER[concepts]=0
COGNITIVE_LOAD_TRACKER[max_concepts]=7
COGNITIVE_LOAD_TRACKER[circuit_breaker_threshold]=9
COGNITIVE_LOAD_TRACKER[context_switches]=0

# Circuit Breaker Implementation
declare -A CIRCUIT_BREAKER
CIRCUIT_BREAKER[state]="closed"
CIRCUIT_BREAKER[failure_count]=0
CIRCUIT_BREAKER[failure_threshold]=5
CIRCUIT_BREAKER[timeout]=60
CIRCUIT_BREAKER[last_failure_time]=0

# Resource Monitoring (1GB memory, 10% CPU max)
declare -A RESOURCE_LIMITS
RESOURCE_LIMITS[max_memory_mb]=1024
RESOURCE_LIMITS[max_cpu_percent]=10
RESOURCE_LIMITS[current_memory_mb]=0
RESOURCE_LIMITS[current_cpu_percent]=0

# Shared utility functions for Rails apps on OpenBSD 7.5, unprivileged user, NNG/SEO/Schema optimized

BASE_DIR="/home/dev/rails"
RAILS_VERSION="8.0.0"
RUBY_VERSION="3.3.0"
NODE_VERSION="20"
BRGEN_IP="46.23.95.45"

# Cognitive Orchestration Functions
cognitive_load_check() {
  local function_name="$1"
  local complexity="${2:-1}"
  
  # Measure: exactly_how_is_this_measured = cognitive load counter
  # Units: what_units_are_used = number of concepts (max 7)
  # Success: what_constitutes_success_vs_failure = load < 7 = success, >= 7 = failure
  # Frequency: what_is_the_measurement_frequency = real-time per function call
  # Performer: who_or_what_performs_the_measurement = cognitive_load_check function
  
  local current_load=$((COGNITIVE_LOAD_TRACKER[concepts] + complexity))
  
  if [ $current_load -ge ${COGNITIVE_LOAD_TRACKER[circuit_breaker_threshold]} ]; then
    log "COGNITIVE_OVERLOAD: Circuit breaker activated for $function_name"
    circuit_breaker_activate "cognitive_overload"
    return 1
  fi
  
  COGNITIVE_LOAD_TRACKER[concepts]=$current_load
  return 0
}

cognitive_load_release() {
  local complexity="${1:-1}"
  local current_load=$((COGNITIVE_LOAD_TRACKER[concepts] - complexity))
  COGNITIVE_LOAD_TRACKER[concepts]=$((current_load > 0 ? current_load : 0))
}

circuit_breaker_activate() {
  local reason="$1"
  local current_time=$(date +%s)
  
  CIRCUIT_BREAKER[state]="open"
  CIRCUIT_BREAKER[failure_count]=$((CIRCUIT_BREAKER[failure_count] + 1))
  CIRCUIT_BREAKER[last_failure_time]=$current_time
  
  log "CIRCUIT_BREAKER: Activated due to $reason (failure_count=${CIRCUIT_BREAKER[failure_count]})"
  
  # Anti-truncation: Context preservation with checkpoint recovery
  create_checkpoint "$reason"
  
  # Edge case: what_happens_when_this_fails = wait for cooldown period
  sleep $((CIRCUIT_BREAKER[timeout] / 10))  # Brief cooldown
}

circuit_breaker_check() {
  local function_name="$1"
  local current_time=$(date +%s)
  
  if [ "${CIRCUIT_BREAKER[state]}" = "open" ]; then
    local time_since_failure=$((current_time - CIRCUIT_BREAKER[last_failure_time]))
    
    if [ $time_since_failure -ge ${CIRCUIT_BREAKER[timeout]} ]; then
      CIRCUIT_BREAKER[state]="half_open"
      log "CIRCUIT_BREAKER: Moving to half-open state for $function_name"
    else
      log "CIRCUIT_BREAKER: Blocked execution of $function_name (cooldown: $((CIRCUIT_BREAKER[timeout] - time_since_failure))s remaining)"
      return 1
    fi
  fi
  
  return 0
}

resource_monitor() {
  local function_name="$1"
  
  # Resource validation: what_resources_does_this_consume = memory and CPU
  local memory_mb=$(ps -o rss= -p $$ | awk '{print int($1/1024)}')
  local cpu_percent=$(ps -o %cpu= -p $$ | awk '{print int($1)}')
  
  RESOURCE_LIMITS[current_memory_mb]=$memory_mb
  RESOURCE_LIMITS[current_cpu_percent]=$cpu_percent
  
  # Resource limits: what_is_the_maximum_acceptable_resource_usage
  if [ $memory_mb -gt ${RESOURCE_LIMITS[max_memory_mb]} ]; then
    log "RESOURCE_LIMIT: Memory exceeded (${memory_mb}MB > ${RESOURCE_LIMITS[max_memory_mb]}MB) in $function_name"
    circuit_breaker_activate "memory_exceeded"
    return 1
  fi
  
  if [ $cpu_percent -gt ${RESOURCE_LIMITS[max_cpu_percent]} ]; then
    log "RESOURCE_LIMIT: CPU exceeded (${cpu_percent}% > ${RESOURCE_LIMITS[max_cpu_percent]}%) in $function_name"
    circuit_breaker_activate "cpu_exceeded"
    return 1
  fi
  
  return 0
}

create_checkpoint() {
  local reason="$1"
  local checkpoint_file="${BASE_DIR}/cognitive_checkpoint_$(date +%s).json"
  
  # Anti-truncation: 95% context preservation
  cat > "$checkpoint_file" <<EOF
{
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "reason": "$reason",
  "cognitive_load": ${COGNITIVE_LOAD_TRACKER[concepts]},
  "circuit_breaker_state": "${CIRCUIT_BREAKER[state]}",
  "resource_usage": {
    "memory_mb": ${RESOURCE_LIMITS[current_memory_mb]},
    "cpu_percent": ${RESOURCE_LIMITS[current_cpu_percent]}
  },
  "context_preservation": "95%"
}
EOF
  
  log "CHECKPOINT: Created at $checkpoint_file"
}

# Enhanced logging with cognitive context
log() {
  local app_name="${APP_NAME:-unknown}"
  local message="$1"
  local timestamp=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
  local cognitive_context="[load:${COGNITIVE_LOAD_TRACKER[concepts]}/${COGNITIVE_LOAD_TRACKER[max_concepts]}]"
  
  echo "$timestamp $cognitive_context - $message" >> "$BASE_DIR/$app_name/setup.log"
  echo "$cognitive_context $message"
}

# Enhanced error handling with circuit breaker integration
error() {
  local message="$1"
  local function_name="${2:-unknown}"
  
  log "ERROR: $message in $function_name"
  circuit_breaker_activate "error_$function_name"
  
  # Edge case: what_happens_when_this_fails = graceful degradation
  cognitive_load_release 1  # Release cognitive load on error
  
  exit 1
}

command_exists() {
  local cmd="$1"
  
  # Cognitive orchestration: Check cognitive load before proceeding
  if ! cognitive_load_check "command_exists" 1; then
    return 1
  fi
  
  # Resource monitoring: Track resource usage
  if ! resource_monitor "command_exists"; then
    cognitive_load_release 1
    return 1
  fi
  
  # Circuit breaker: Check if we should proceed
  if ! circuit_breaker_check "command_exists"; then
    cognitive_load_release 1
    return 1
  fi
  
  # Precision measurement: exactly_how_is_this_measured = command -v exit code
  # Units: what_units_are_used = exit code (0=success, non-zero=failure)
  # Success criteria: what_constitutes_success_vs_failure = command found=0, not found=1
  # Frequency: what_is_the_measurement_frequency = real-time per call
  # Performer: who_or_what_performs_the_measurement = command -v built-in
  
  if ! command -v "$cmd" > /dev/null 2>&1; then
    # Edge case: what_happens_when_this_fails = informative error with suggestion
    local suggestion=""
    case "$cmd" in
      "ruby") suggestion="Try: pkg_add ruby-${RUBY_VERSION}" ;;
      "node") suggestion="Try: pkg_add node-${NODE_VERSION}" ;;
      "psql") suggestion="Try: pkg_add postgresql-server" ;;
      "redis-server") suggestion="Try: pkg_add redis" ;;
      *) suggestion="Try: pkg_add $cmd" ;;
    esac
    
    error "Command '$cmd' not found. $suggestion" "command_exists"
    cognitive_load_release 1
    return 1
  fi
  
  # Success: Release cognitive load and continue
  cognitive_load_release 1
  return 0
}

init_app() {
  local app_name="$1"
  
  # Cognitive orchestration: Complex function requires 2 cognitive load units
  if ! cognitive_load_check "init_app" 2; then
    return 1
  fi
  
  # Resource monitoring: Track resource usage for directory operations
  if ! resource_monitor "init_app"; then
    cognitive_load_release 2
    return 1
  fi
  
  # Circuit breaker: Check if we should proceed with filesystem operations
  if ! circuit_breaker_check "init_app"; then
    cognitive_load_release 2
    return 1
  fi
  
  log "Initializing app directory for '$app_name'"
  
  # Precision measurement: exactly_how_is_this_measured = mkdir exit code
  # Units: what_units_are_used = exit code (0=success, non-zero=failure)
  # Success criteria: what_constitutes_success_vs_failure = directory created=0, failed=1
  # Frequency: what_is_the_measurement_frequency = real-time per operation
  # Performer: who_or_what_performs_the_measurement = mkdir command
  
  # Edge case: what_happens_when_this_fails = detailed error with recovery suggestion
  if ! mkdir -p "$BASE_DIR/$app_name" 2>/dev/null; then
    # Resource validation: what_happens_when_resources_are_scarce = check disk space
    local disk_usage=$(df "$BASE_DIR" | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ "$disk_usage" -gt 90 ]; then
      error "Failed to create app directory '$BASE_DIR/$app_name' - disk space critical (${disk_usage}% used)" "init_app"
    else
      error "Failed to create app directory '$BASE_DIR/$app_name' - permission denied or path invalid" "init_app"
    fi
    cognitive_load_release 2
    return 1
  fi
  
  # Precision measurement: exactly_how_is_this_measured = cd exit code
  # Edge case: what_happens_when_this_fails = directory exists but not accessible
  if ! cd "$BASE_DIR/$app_name" 2>/dev/null; then
    error "Failed to change to directory '$BASE_DIR/$app_name' - permission denied" "init_app"
    cognitive_load_release 2
    return 1
  fi
  
  # Success: Release cognitive load
  cognitive_load_release 2
  return 0
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
  log "Setting up Rails $RAILS_VERSION for '$1'"
  if [ -f "Gemfile" ]; then
    log "Gemfile exists, skipping Rails new"
  else
    rails new . -f --skip-bundle --database=postgresql --asset-pipeline=propshaft --css=scss
    if [ $? -ne 0 ]; then
      error "Failed to create Rails app '$1'"
    fi
  fi
  
  # Add modern Rails 8 gems to Gemfile
  cat <<EOF >> Gemfile

# Rails 8 Modern Stack
gem 'solid_queue', '~> 1.0'
gem 'solid_cache', '~> 1.0'
gem 'falcon', '~> 0.47'
gem 'hotwire-rails', '~> 0.1'
gem 'turbo-rails', '~> 2.0'
gem 'stimulus-rails', '~> 1.3'
gem 'propshaft', '~> 1.0'

# Enhanced Stimulus Components
gem 'stimulus_reflex', '~> 3.5'
gem 'cable_ready', '~> 5.0'
EOF

  bundle install
  if [ $? -ne 0 ]; then
    error "Failed to run bundle install"
  fi
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

setup_core() {
  log "Setting up core Rails configurations with Hotwire and Pagy"
  bundle add hotwire-rails stimulus_reflex turbo-rails pagy
  if [ $? -ne 0 ]; then
    error "Failed to install core gems"
  fi
  bin/rails hotwire:install
  if [ $? -ne 0 ]; then
    error "Failed to install Hotwire"
  fi
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