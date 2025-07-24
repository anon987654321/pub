#!/usr/bin/env zsh
set -e

# Enhanced Rails 8 Brgen Installer - Production-ready social platform
# Integrates existing Rails 8 app with comprehensive ecosystem components

APP_NAME="brgen"
BASE_DIR="/home/dev/rails"
BRGEN_IP="${BRGEN_IP:-46.23.95.45}"
RAILS_VERSION="8.0.2"
RUBY_VERSION="3.2.3"
NODE_VERSION="20"

# Source shared utilities if available
if [ -f "../__shared.sh" ]; then
  source "../__shared.sh"
else
  # Define basic functions if shared file not available
  log() {
    echo "$(date -u +'%Y-%m-%dT%H:%M:%SZ') - $1"
  }
  
  error() {
    log "ERROR: $1"
    exit 1
  }
  
  command_exists() {
    command -v "$1" > /dev/null 2>&1 || error "Command '$1' not found. Please install it."
  }
fi

# Enhanced logging with progress tracking
log_progress() {
  local phase="$1"
  local message="$2"
  log "[$phase] $message"
}

# Phase 1: Environment and Dependencies Setup
setup_environment() {
  log_progress "ENV" "Setting up Rails 8 environment"
  
  # Check required commands
  command_exists "ruby"
  command_exists "node"
  command_exists "yarn"
  command_exists "git"
  
  # Verify versions
  if ! ruby -v | grep -q "3.2"; then
    log "Warning: Ruby 3.2+ recommended for Rails 8"
  fi
  
  if ! node -v | grep -q "v20"; then
    log "Warning: Node.js 20+ recommended for Rails 8"
  fi
  
  # Install essential gems
  gem install bundler rails
  
  log_progress "ENV" "Environment setup complete"
}

# Phase 2: Rails 8 Application Setup
setup_rails_app() {
  log_progress "RAILS" "Setting up Rails 8 application"
  
  # Use existing app if available, otherwise create new
  if [ -d "app" ]; then
    log_progress "RAILS" "Using existing Rails application in app/"
    cd app
  else
    log_progress "RAILS" "Creating new Rails 8 application"
    rails new "$APP_NAME" \
      --database=postgresql \
      --css=sass \
      --javascript=esbuild \
      --skip-test \
      --api=false
    cd "$APP_NAME"
  fi
  
  # Ensure Rails 8 features are available
  if ! bundle exec rails --version | grep -q "8.0"; then
    log_progress "RAILS" "Upgrading to Rails 8.0.2"
    bundle update rails
  fi
  
  log_progress "RAILS" "Rails application setup complete"
}

# Phase 3: Install Essential Gems for Production
setup_production_gems() {
  log_progress "GEMS" "Installing production-ready gem stack"
  
  # Add gems to Gemfile if not present
  local gems_to_add=(
    'gem "stimulus_reflex", "~> 3.5"'
    'gem "acts_as_tenant"'
    'gem "pagy"'
    'gem "pundit"'
    'gem "devise"'
    'gem "solid_queue"'
    'gem "solid_cache"'
    'gem "kamal", require: false'
    'gem "thruster", require: false'
    'gem "image_processing"'
    'gem "meta-tags"'
    'gem "sitemap_generator"'
    'gem "rack-mini-profiler"'
    'gem "brakeman", group: [:development, :test]'
    'gem "rubocop-rails-omakase", group: [:development, :test]'
  )
  
  for gem_line in "${gems_to_add[@]}"; do
    if ! grep -q "$(echo "$gem_line" | cut -d'"' -f2)" Gemfile; then
      echo "$gem_line" >> Gemfile
    fi
  done
  
  bundle install
  
  log_progress "GEMS" "Production gems installed"
}

# Phase 4: StimulusReflex and Real-time Features
setup_realtime_features() {
  log_progress "REALTIME" "Configuring StimulusReflex and real-time features"
  
  # Install StimulusReflex if not already done
  if [ ! -d "app/reflexes" ]; then
    rails stimulus_reflex:install --skip-bundle
  fi
  
  # Enable caching for development
  rails dev:cache 2>/dev/null || true
  
  # Configure Redis for production
  if ! grep -q "redis" config/cable.yml; then
    cat > config/cable.yml << 'EOF'
development:
  adapter: redis
  url: redis://localhost:6379/1

test:
  adapter: test

production:
  adapter: redis
  url: <%= ENV.fetch("REDIS_URL") { "redis://localhost:6379/1" } %>
  channel_prefix: brgen_production
EOF
  fi
  
  log_progress "REALTIME" "Real-time features configured"
}

# Phase 5: Database and Multi-tenancy Setup
setup_database_and_tenancy() {
  log_progress "DATABASE" "Setting up database and multi-tenancy"
  
  # Generate essential models if they don't exist
  if [ ! -f "app/models/user.rb" ]; then
    rails generate devise:install
    rails generate devise User
  fi
  
  if [ ! -f "app/models/community.rb" ]; then
    rails generate model Community name:string subdomain:string settings:json
  fi
  
  if [ ! -f "app/models/post.rb" ]; then
    rails generate model Post title:string content:text user:references community:references published:boolean
  fi
  
  if [ ! -f "app/models/comment.rb" ]; then
    rails generate model Comment content:text user:references post:references
  fi
  
  # Setup acts_as_tenant
  if ! grep -q "acts_as_tenant" app/models/post.rb 2>/dev/null; then
    cat >> app/models/post.rb << 'EOF'

# Multi-tenancy
acts_as_tenant :community
EOF
  fi
  
  # Run migrations
  rails db:create db:migrate 2>/dev/null || rails db:migrate
  
  log_progress "DATABASE" "Database and tenancy setup complete"
}

# Phase 6: Frontend and Asset Pipeline
setup_frontend() {
  log_progress "FRONTEND" "Setting up modern frontend pipeline"
  
  # Install JavaScript dependencies
  if [ ! -f "package.json" ]; then
    yarn init -y
  fi
  
  # Add essential npm packages
  local npm_packages=(
    "@hotwired/stimulus"
    "@hotwired/turbo-rails"
    "stimulus_reflex"
    "cable_ready"
    "sass"
    "autoprefixer"
    "postcss"
    "esbuild"
  )
  
  for package in "${npm_packages[@]}"; do
    if ! grep -q "\"$package\"" package.json; then
      yarn add "$package"
    fi
  done
  
  # Build assets
  rails assets:precompile RAILS_ENV=development 2>/dev/null || true
  
  log_progress "FRONTEND" "Frontend pipeline configured"
}

# Phase 7: Security and Performance Configuration
setup_security_performance() {
  log_progress "SECURITY" "Configuring security and performance features"
  
  # Content Security Policy
  if [ ! -f "config/initializers/content_security_policy.rb" ]; then
    cat > config/initializers/content_security_policy.rb << 'EOF'
# Define an application-wide content security policy
Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self, :https
    policy.font_src    :self, :https, :data
    policy.img_src     :self, :https, :data
    policy.object_src  :none
    policy.script_src  :self, :https
    policy.style_src   :self, :https, :unsafe_inline
    policy.connect_src :self, :https, "ws:", "wss:"
  end
  
  config.content_security_policy_nonce_generator = -> request { SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w(script-src)
end
EOF
  fi
  
  # Force SSL in production
  if ! grep -q "force_ssl" config/environments/production.rb; then
    sed -i 's/# config.force_ssl = true/config.force_ssl = true/' config/environments/production.rb
  fi
  
  log_progress "SECURITY" "Security configuration complete"
}

# Phase 8: Testing Infrastructure
setup_testing() {
  log_progress "TESTING" "Setting up comprehensive testing infrastructure"
  
  # Add testing gems
  local test_gems=(
    'gem "rspec-rails", group: [:development, :test]'
    'gem "factory_bot_rails", group: [:development, :test]'
    'gem "faker", group: [:development, :test]'
    'gem "capybara", group: :test'
    'gem "selenium-webdriver", group: :test'
    'gem "simplecov", group: :test, require: false'
  )
  
  for gem_line in "${test_gems[@]}"; do
    if ! grep -q "$(echo "$gem_line" | cut -d'"' -f2)" Gemfile; then
      echo "$gem_line" >> Gemfile
    fi
  done
  
  bundle install
  
  # Initialize RSpec if not present
  if [ ! -d "spec" ]; then
    rails generate rspec:install
  fi
  
  log_progress "TESTING" "Testing infrastructure ready"
}

# Phase 9: Deployment Configuration
setup_deployment() {
  log_progress "DEPLOY" "Configuring deployment with Kamal"
  
  # Initialize Kamal if not present
  if [ ! -f "config/deploy.yml" ]; then
    kamal init 2>/dev/null || log "Kamal configuration skipped (not available)"
  fi
  
  # Create Dockerfile if not present
  if [ ! -f "Dockerfile" ]; then
    cat > Dockerfile << 'EOF'
FROM ruby:3.2-alpine

RUN apk add --no-cache \
  build-base \
  postgresql-dev \
  nodejs \
  yarn \
  git

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY package.json yarn.lock ./
RUN yarn install

COPY . .

RUN rails assets:precompile

EXPOSE 3000

CMD ["rails", "server", "-b", "0.0.0.0"]
EOF
  fi
  
  log_progress "DEPLOY" "Deployment configuration complete"
}

# Phase 10: Integration with Ecosystem Components
setup_ecosystem_integration() {
  log_progress "ECOSYSTEM" "Integrating AI3, bplans, postpro, and OpenBSD components"
  
  # Create lib directory for integrations
  mkdir -p lib/integrations
  
  # AI3 Integration
  if [ -d "../../ai3" ]; then
    log_progress "ECOSYSTEM" "Integrating AI3 system"
    ln -sf "../../ai3" lib/integrations/ai3 2>/dev/null || cp -r "../../ai3" lib/integrations/
  fi
  
  # Bplans Integration
  if [ -d "../../bplans" ]; then
    log_progress "ECOSYSTEM" "Integrating business planning components"
    ln -sf "../../bplans" lib/integrations/bplans 2>/dev/null || cp -r "../../bplans" lib/integrations/
  fi
  
  # Postpro Integration
  if [ -d "../../postpro" ]; then
    log_progress "ECOSYSTEM" "Integrating post-processing utilities"
    ln -sf "../../postpro" lib/integrations/postpro 2>/dev/null || cp -r "../../postpro" lib/integrations/
  fi
  
  # OpenBSD Scripts Integration
  if [ -d "../../openbsd" ]; then
    log_progress "ECOSYSTEM" "Integrating OpenBSD deployment"
    ln -sf "../../openbsd" lib/integrations/openbsd 2>/dev/null || cp -r "../../openbsd" lib/integrations/
  fi
  
  log_progress "ECOSYSTEM" "Ecosystem integration complete"
}

# Phase 11: PWA Configuration
setup_pwa() {
  log_progress "PWA" "Configuring Progressive Web App features"
  
  # Generate PWA manifest
  if [ ! -f "app/views/pwa/manifest.json.erb" ]; then
    mkdir -p app/views/pwa
    cat > app/views/pwa/manifest.json.erb << 'EOF'
{
  "name": "Brgen Platform",
  "short_name": "Brgen",
  "description": "Multi-tenant social and marketplace platform",
  "start_url": "/",
  "display": "standalone",
  "theme_color": "#000000",
  "background_color": "#ffffff",
  "icons": [
    {
      "src": "<%= asset_path('icon-192.png') %>",
      "sizes": "192x192",
      "type": "image/png"
    },
    {
      "src": "<%= asset_path('icon-512.png') %>",
      "sizes": "512x512",
      "type": "image/png"
    }
  ]
}
EOF
  fi
  
  # Add PWA routes
  if ! grep -q "pwa_manifest" config/routes.rb; then
    cat >> config/routes.rb << 'EOF'

  # PWA routes
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
EOF
  fi
  
  log_progress "PWA" "PWA configuration complete"
}

# Phase 12: Final Optimization and Documentation
finalize_setup() {
  log_progress "FINALIZE" "Running final optimizations and documentation"
  
  # Run security scan
  if command -v brakeman >/dev/null 2>&1; then
    bundle exec brakeman --quiet --format plain > security_report.txt 2>/dev/null || true
  fi
  
  # Run linting
  if command -v rubocop >/dev/null 2>&1; then
    bundle exec rubocop --auto-correct 2>/dev/null || true
  fi
  
  # Generate documentation
  if [ ! -f "README_DEPLOYMENT.md" ]; then
    cat > README_DEPLOYMENT.md << 'EOF'
# Brgen Rails 8 Platform - Deployment Guide

## Quick Start

1. Install dependencies:
   ```bash
   bundle install
   yarn install
   ```

2. Setup database:
   ```bash
   rails db:setup
   ```

3. Start development server:
   ```bash
   bin/dev
   ```

## Production Deployment

1. Build for production:
   ```bash
   rails assets:precompile RAILS_ENV=production
   ```

2. Deploy with Kamal:
   ```bash
   kamal deploy
   ```

## Features

- Rails 8.0.2 with modern tooling
- StimulusReflex for real-time features
- Multi-tenancy with ActsAsTenant
- Progressive Web App (PWA) ready
- Comprehensive security configuration
- OpenBSD deployment optimized

## Ecosystem Integration

- AI3: AI assistant system integration
- Bplans: Business planning components
- Postpro: Media processing utilities
- OpenBSD: Deployment automation

EOF
  fi
  
  log_progress "FINALIZE" "Setup complete! 🎉"
}

# Main execution flow
main() {
  log "🚀 Starting Rails 8 Brgen Platform Setup"
  log "========================================="
  
  setup_environment
  setup_rails_app
  setup_production_gems
  setup_realtime_features
  setup_database_and_tenancy
  setup_frontend
  setup_security_performance
  setup_testing
  setup_deployment
  setup_ecosystem_integration
  setup_pwa
  finalize_setup
  
  log ""
  log "✅ Rails 8 Brgen Platform setup complete!"
  log "📖 See README_DEPLOYMENT.md for next steps"
  log "🌐 Start development: cd app && bin/dev"
  log "========================================="
}

# Execute main function if script is run directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi