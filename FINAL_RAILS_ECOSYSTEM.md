# § Final Rails Ecosystem

# FINAL RAILS ECOSYSTEM - Complete Application Suite Architecture

## Executive Summary

This document provides comprehensive, production-ready documentation for the complete Rails ecosystem supporting hyper-localized social networks, AI-enhanced applications, and specialized business platforms.
<!-- TODO: Break into shorter sentences (38 words > 15) --> The ecosystem implements modern Rails 8.0+ patterns with Hotwire, Progressive Web App capabilities, and seamless OpenBSD deployment integration.
<!-- TODO: Break into shorter sentences (18 words > 15) --> ## Rails Ecosystem Architecture Overview

### Technology Stack Foundation

**Modern Rails 8.0+ Application Suite:**
```
  Rails Ecosystem Infrastructure
  ├── Core Technology Stack (Rails 8.0+, Ruby 3.3+, PostgreSQL, Redis)
  ├── Frontend Framework (Hotwire: Turbo + Stimulus + StimulusReflex)
  ├── Progressive Web App (Service Workers + Offline Capabilities)
  ├── Authentication System (Devise + devise-guests + omniauth-vipps)
  ├── Real-time Features (ActionCable + StimulusReflex + Falcon Server)
  ├── AI Integration (OpenAI + Replicate + Custom ML Models)
  ├── Database Architecture (PostgreSQL + Redis + Vector Extensions)
  └── Deployment Strategy (OpenBSD + httpd + relayd + acme-client)
```

### Application Portfolio

**Seven Core Applications:**
1.
<!-- TODO: Break into shorter sentences (100 words > 15) --> **Brgen Platform** - Hyper-localized social network (40+ cities)
2. **Amber Fashion** - AI-enhanced wardrobe and style assistant
3. **Banking Revolution** - "Last bank you'll ever need" architecture
4. **BSDPorts** - OpenBSD package management and community
5. **Hjerterom** - Mental health and wellness platform
6. **PrivCam** - Privacy-focused video communication
7. **Blognet Network** - Multi-domain blog management platform

## Shared Infrastructure Architecture

### Universal Setup Framework (`__shared.sh`)

```bash
#!/usr/bin/env zsh
# Shared setup script for Rails applications
# Supports: Rails 8.0+, Ruby 3.3+, OpenBSD 7.8+

set -e

# Global configuration
RAILS_VERSION="8.0.0"
RUBY_VERSION="3.3.5"
BASE_DIR="/home"
LOG_FILE="logs/setup_${APP_NAME}.log"

# Logging utility
log() {
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $1" | tee -a "$LOG_FILE"
}

# Error handling
error_exit() {
  log "ERROR: $1"
  exit 1
}

# Database setup with optimizations
setup_postgresql() {
  local app_name="$1"
  local db_name="${app_name}_production"
  local db_user="${app_name}_user"
  local db_pass="$(openssl rand -hex 32)"
  
  log "Setting up PostgreSQL for $app_name"
  
  # Create database and user
  doas -u _postgresql createdb "$db_name" || error_exit "Failed to create database"
  doas -u _postgresql psql -c "CREATE USER $db_user WITH PASSWORD '$db_pass';" || error_exit "Failed to create user"
  doas -u _postgresql psql -c "GRANT ALL PRIVILEGES ON DATABASE $db_name TO $db_user;" || error_exit "Failed to grant privileges"
  
  # Enable extensions for advanced features
  doas -u _postgresql psql -d "$db_name" -c "CREATE EXTENSION IF NOT EXISTS pg_trgm;" # Full-text search
  doas -u _postgresql psql -d "$db_name" -c "CREATE EXTENSION IF NOT EXISTS vector;" # Vector similarity
  doas -u _postgresql psql -d "$db_name" -c "CREATE EXTENSION IF NOT EXISTS postgis;" # Geospatial
  
  # Generate database configuration
  cat > config/database.yml <<EOF
default: &default
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 10 } %>
  username: $db_user
  password: $db_pass
  host: localhost
  
development:
  <<: *default
  database: ${app_name}_development
  
test:
  <<: *default
  database: ${app_name}_test
  
production:
  <<: *default
  database: $db_name
  url: <%= ENV["DATABASE_URL"] %>
  # Performance optimizations
  prepared_statements: true
  advisory_locks: true
  connect_timeout: 5
  checkout_timeout: 5
  variables:
    statement_timeout: 30s
    lock_timeout: 10s
EOF
  
  log "PostgreSQL setup completed for $app_name"
}

# Redis configuration for caching and sessions
setup_redis() {
  local app_name="$1"
  
  log "Setting up Redis for $app_name"
  
  # Ensure Redis is running
  doas rcctl enable redis
  doas rcctl start redis
  
  # Configure Redis for Rails
  cat > config/initializers/redis.rb <<EOF
# Redis configuration for $app_name
Redis.current = Redis.new(
  url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0"),
  timeout: 1,
  reconnect_attempts: 3,
  reconnect_delay: 1.5
)

# Cache store configuration
Rails.application.configure do
  config.cache_store = :redis_cache_store, {
    url: ENV.fetch("REDIS_URL", "redis://localhost:6379/1"),
    expires_in: 1.hour,
    race_condition_ttl: 5.seconds,
    compress: true,
    compression_threshold: 1.kilobyte
  }
  
  # Session store
  config.session_store :redis_store, {
    servers: [ENV.fetch("REDIS_URL", "redis://localhost:6379/2")],
    expire_after: 2.weeks,
    key: "_${app_name}_session",
    threadsafe: true
  }
end
EOF
  
  log "Redis setup completed for $app_name"
}

# Authentication system with Norwegian BankID/Vipps
setup_authentication() {
  local app_name="$1"
  
  log "Setting up authentication for $app_name"
  
  # Add authentication gems
  cat >> Gemfile <<EOF

# Authentication and authorization
gem "devise", "~> 4.9"
gem "devise-guests", "~> 0.8"
gem "omniauth", "~> 2.1"
gem "omniauth-openid-connect", "~> 0.7"
gem "omniauth-rails_csrf_protection", "~> 1.0"
EOF
  
  bundle install
  
  # Generate Devise configuration
  bin/rails generate devise:install
  bin/rails generate devise User
  bin/rails generate devise:views
  
  # Configure guest users
  cat >> config/initializers/devise.rb <<EOF

# Guest user configuration
config.guest_user_class = "GuestUser"
Devise.setup do |config|
  config.allow_unconfirmed_access_for = 2.days
  config.confirm_within = 3.days
  config.maximum_attempts = 5
  config.unlock_in = 1.hour
  config.reset_password_within = 6.hours
end
EOF
  
  # Norwegian Vipps OAuth strategy
  mkdir -p lib/omniauth/strategies
  cat > lib/omniauth/strategies/vipps.rb <<EOF
require "omniauth-openid-connect"

module OmniAuth
  module Strategies
    class Vipps < OmniAuth::Strategies::OpenIDConnect
      option :name, "vipps"
      
      option :client_options, {
        identifier: ENV["VIPPS_CLIENT_ID"],
        secret: ENV["VIPPS_CLIENT_SECRET"],
        authorization_endpoint: "https://api.vipps.no/oauth/authorize",
        token_endpoint: "https://api.vipps.no/oauth/token",
        userinfo_endpoint: "https://api.vipps.no/userinfo",
        jwks_uri: "https://api.vipps.no/.well-known/jwks.json"
      }
      
      option :scope, "openid profile email"
      option :response_type, "code"
      
      uid { raw_info["sub"] }
      
      info do
        {
          email: raw_info["email"],
          name: raw_info["name"],
          phone: raw_info["phone_number"],
          verified: raw_info["email_verified"]
        }
      end
    end
  end
end
EOF
  
  # Configure OmniAuth
  cat > config/initializers/omniauth.rb <<EOF
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :vipps, ENV["VIPPS_CLIENT_ID"], ENV["VIPPS_CLIENT_SECRET"]
end

OmniAuth.config.allowed_request_methods = [:post, :get]
OmniAuth.config.silence_get_warning = true
EOF
  
  log "Authentication setup completed for $app_name"
}

# Real-time features with Hotwire and StimulusReflex
setup_realtime_features() {
  local app_name="$1"
  
  log "Setting up real-time features for $app_name"
  
  # Add real-time gems
  cat >> Gemfile <<EOF

# Real-time features
gem "stimulus_reflex", "~> 3.5"
gem "cable_ready", "~> 5.0"
gem "turbo-rails", "~> 1.5"
gem "stimulus-rails", "~> 1.3"
gem "falcon", "~> 0.47"
EOF
  
  bundle install
  
  # Install StimulusReflex
  bin/rails stimulus_reflex:install
  
  # Configure ActionCable for production
  cat > config/cable.yml <<EOF
development:
  adapter: redis
  url: redis://localhost:6379/3
  channel_prefix: ${app_name}_dev

test:
  adapter: test

production:
  adapter: redis
  url: <%= ENV.fetch("REDIS_URL", "redis://localhost:6379/3") %>
  channel_prefix: ${app_name}_prod
EOF
  
  # JavaScript dependencies
  bin/importmap pin @hotwired/turbo-rails
  bin/importmap pin @hotwired/stimulus
  bin/importmap pin stimulus_reflex
  bin/importmap pin cable_ready
  
  # Configure Falcon server
  cat > config/falcon.rb <<EOF
#!/usr/bin/env -S falcon host
# Falcon configuration for $app_name

load :rack, :self_signed_tls, :supervisor

hostname "$app_name.local"
port 3000

# Performance optimizations
count ENV.fetch("WEB_CONCURRENCY", 2).to_i

# Security headers
rack do |builder|
  builder.use Rack::CommonLogger
  builder.use Rack::ShowExceptions
  builder.use Rack::Lint
  builder.run Rails.application
end

# TLS configuration for development
self_signed_tls
EOF
  
  log "Real-time features setup completed for $app_name"
}

# Progressive Web App configuration
setup_pwa() {
  local app_name="$1"
  
  log "Setting up PWA for $app_name"
  
  # Service Worker
  mkdir -p app/javascript
  cat > app/javascript/service-worker.js <<EOF
// Service Worker for $app_name PWA
const CACHE_NAME = "${app_name}-v1.0.0";
const STATIC_CACHE = "${app_name}-static-v1.0.0";
const DYNAMIC_CACHE = "${app_name}-dynamic-v1.0.0";

const STATIC_ASSETS = [
  "/",
  "/manifest.json",
  "/offline.html",
  "/assets/application.css",
  "/assets/application.js"
];

// Install event
self.addEventListener("install", (event) => {
  console.log("Service Worker installing...");
  event.waitUntil(
    caches.open(STATIC_CACHE)
      .then((cache) => cache.addAll(STATIC_ASSETS))
      .then(() => self.skipWaiting())
  );
});

// Activate event
self.addEventListener("activate", (event) => {
  console.log("Service Worker activating...");
  event.waitUntil(
    caches.keys()
      .then((cacheNames) => {
        return Promise.all(
          cacheNames.map((cacheName) => {
            if (cacheName !== STATIC_CACHE && cacheName !== DYNAMIC_CACHE) {
              return caches.delete(cacheName);
            }
          })
        );
      })
      .then(() => self.clients.claim())
  );
});

// Fetch event with network-first strategy for dynamic content
self.addEventListener("fetch", (event) => {
  const { request } = event;
  
  // Skip non-GET requests
  if (request.method !== "GET") return;
  
  // Handle static assets with cache-first strategy
  if (STATIC_ASSETS.includes(new URL(request.url).pathname)) {
    event.respondWith(
      caches.match(request)
        .then((response) => response || fetch(request))
    );
    return;
  }
  
  // Handle API requests with network-first strategy
  if (request.url.includes("/api/")) {
    event.respondWith(
      fetch(request)
        .then((response) => {
          if (response.ok) {
            const responseClone = response.clone();
            caches.open(DYNAMIC_CACHE)
              .then((cache) => cache.put(request, responseClone));
          }
          return response;
        })
        .catch(() => {
          return caches.match(request)
            .then((response) => response || caches.match("/offline.html"));
        })
    );
    return;
  }
  
  // Default: network-first with cache fallback
  event.respondWith(
    fetch(request)
      .catch(() => {
        return caches.match(request)
          .then((response) => response || caches.match("/offline.html"));
      })
  );
});

// Background sync for offline actions
self.addEventListener("sync", (event) => {
  if (event.tag === "background-sync") {
    event.waitUntil(doBackgroundSync());
  }
});

function doBackgroundSync() {
  // Handle offline actions when back online
  return fetch("/api/sync")
    .then((response) => {
      console.log("Background sync completed");
      return response;
    })
    .catch((error) => {
      console.error("Background sync failed:", error);
    });
}
EOF
  
  # Web App Manifest
  cat > app/views/layouts/manifest.json.erb <<EOF
{
  "name": "<%= I18n.t('app.full_name', default: '$app_name') %>",
  "short_name": "<%= I18n.t('app.short_name', default: '$app_name') %>",
  "description": "<%= I18n.t('app.description', default: 'Progressive Web App') %>",
  "start_url": "/",
  "scope": "/",
  "display": "standalone",
  "orientation": "portrait-primary",
  "theme_color": "#000000",
  "background_color": "#ffffff",
  "lang": "en",
  "dir": "ltr",
  "icons": [
    {
      "src": "/icon-192.png",
      "sizes": "192x192",
      "type": "image/png",
      "purpose": "any maskable"
    },
    {
      "src": "/icon-512.png",
      "sizes": "512x512",
      "type": "image/png",
      "purpose": "any maskable"
    }
  ],
  "shortcuts": [
    {
      "name": "New Post",
      "short_name": "Post",
      "description": "Create a new post",
      "url": "/posts/new",
      "icons": [{ "src": "/post-icon.png", "sizes": "96x96" }]
    }
  ],
  "categories": ["social", "lifestyle"],
  "screenshots": [
    {
      "src": "/screenshot-wide.png",
      "sizes": "1280x720",
      "type": "image/png",
      "form_factor": "wide"
    },
    {
      "src": "/screenshot-narrow.png", 
      "sizes": "750x1334",
      "type": "image/png",
      "form_factor": "narrow"
    }
  ]
}
EOF
  
  # Offline page
  cat > app/views/layouts/offline.html.erb <<EOF
<!DOCTYPE html>
<html>
<head>
  <title>Offline - <%= I18n.t('app.name', default: '$app_name') %></title>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <%= stylesheet_link_tag "application", media: "all" %>
</head>
<body>
  <main>
    <section>
      <h1>You're offline</h1>
      <p>Check your internet connection and try again.</p>
      <button onclick="window.location.reload()">Retry</button>
    </section>
  </main>
</body>
</html>
EOF
  
  log "PWA setup completed for $app_name"
}

# AI Integration setup
setup_ai_integration() {
  local app_name="$1"
  
  log "Setting up AI integration for $app_name"
  
  # Add AI gems
  cat >> Gemfile <<EOF

# AI and Machine Learning
gem "ruby-openai", "~> 6.3"
gem "replicate-ruby", "~> 0.2"
gem "neighbor", "~> 0.3"  # Vector similarity
gem "pg_search", "~> 2.3"  # Full-text search
EOF
  
  bundle install
  
  # AI service configuration
  mkdir -p app/services/ai
  cat > app/services/ai/openai_service.rb <<EOF
class AI::OpenaiService
  include HTTParty
  base_uri "https://api.openai.com/v1"
  
  def initialize
    @headers = {
      "Authorization" => "Bearer #{ENV['OPENAI_API_KEY']}",
      "Content-Type" => "application/json"
    }
  end
  
  def chat_completion(messages:, model: "gpt-4", temperature: 0.7)
    body = {
      model: model,
      messages: messages,
      temperature: temperature,
      max_tokens: 1000
    }
    
    response = self.class.post("/chat/completions", 
      headers: @headers,
      body: body.to_json
    )
    
    handle_response(response)
  end
  
  def generate_embedding(text:, model: "text-embedding-3-small")
    body = {
      model: model,
      input: text
    }
    
    response = self.class.post("/embeddings",
      headers: @headers,
      body: body.to_json
    )
    
    handle_response(response)
  end
  
  private
  
  def handle_response(response)
    if response.success?
<!-- TODO: Break into shorter sentences (1330 words > 15) --> response.parsed_response
    else
      Rails.logger.error "OpenAI API Error: #{response.body}"
      raise "OpenAI API Error: #{response.code}"
    end
  end
end
EOF
  
  # Vector similarity setup
  cat > db/migrate/001_enable_vector_extension.rb <<EOF
class EnableVectorExtension < ActiveRecord::Migration[8.0]
  def change
    enable_extension "vector"
  end
end
EOF
  
  log "AI integration setup completed for $app_name"
}

# Main setup function
main() {
  local app_name="$1"
  
  if [ -z "$app_name" ]; then
    echo "Usage: setup_shared.sh <app_name>"
    exit 1
  fi
  
  export APP_NAME="$app_name"
  
  log "Starting setup for $app_name"
  
  # Create application directory structure
  mkdir -p "$BASE_DIR/$app_name"
  cd "$BASE_DIR/$app_name"
  
  # Create new Rails application if it doesn't exist
  if [ !
<!-- TODO: Break into shorter sentences (93 words > 15) --> -f "Gemfile" ]; then
    rails new . \
      --database=postgresql \
      --css=scss \
      --javascript=importmap \
      --skip-test \
      --skip-bundle \
      --force
  fi
  
  # Run setup functions
  setup_postgresql "$app_name"
  setup_redis "$app_name"
  setup_authentication "$app_name"
  setup_realtime_features "$app_name"
  setup_pwa "$app_name"
  setup_ai_integration "$app_name"
  
  # Install dependencies
  bundle install
  bin/setup
  
  log "Setup completed for $app_name"
}

# Export functions for use by individual app scripts
export -f log error_exit setup_postgresql setup_redis setup_authentication
export -f setup_realtime_features setup_pwa setup_ai_integration
```

## Brgen Platform - Hyper-Localized Social Network

### Architecture Overview

**Brgen Platform Components:**
```
  Brgen Social Network
  ├── Core Social Features (Communities, Posts, Comments, Reactions)
  ├── Marketplace Integration (E-commerce with AI recommendations)
  ├── Music Sharing Platform (Playlist creation and sharing)
  ├── Dating Service (Location-based matching)
  ├── TV Channel (AI-generated content streaming)
  ├── Food Delivery (Street food vendor network)
  └── Geolocation Services (City-specific content)
```

### Database Schema

```ruby
# Core social models
class Community < ApplicationRecord
  has_many :posts, dependent: :destroy
  has_many :members, through: :community_memberships, source: :user
  has_many :community_memberships, dependent: :destroy
  
  validates :name, presence: true, uniqueness: { scope: :city }
  validates :city, presence: true
  
  scope :by_city, ->(city) { where(city: city) }
  scope :popular, -> { joins(:posts).group(:id).order('COUNT(posts.id) DESC') }
  
  include PgSearch::Model
  pg_search_scope :search_communities,
    against: [:name, :description],
    using: {
      tsearch: { prefix: true },
      trigram: { threshold: 0.3 }
    }
end

class Post < ApplicationRecord
  belongs_to :user
  belongs_to :community
  has_many :comments, dependent: :destroy
  has_many :reactions, dependent: :destroy
  has_many :streams, dependent: :destroy
  has_many_attached :media
  
  validates :title, presence: true, length: { maximum: 255 }
  validates :content, presence: true, length: { maximum: 10000 }
  
  scope :trending, -> { 
    where('created_at > ?', 24.hours.ago)
      .joins(:reactions)
      .group(:id)
      .order('COUNT(reactions.id) DESC')
  }
  
  scope :by_location, ->(lat, lng, radius = 10) {
    where(
      "ST_DWithin(location, ST_MakePoint(?, ?), ?)",
      lng, lat, radius * 1000
    )
  }
  
  def karma_score
    upvotes = reactions.where(kind: 'upvote').count
    downvotes = reactions.where(kind: 'downvote').count
    (upvotes - downvotes) + (comments.count * 0.5)
  end
  
  # AI-powered content analysis
  def analyze_sentiment
    AI::OpenaiService.new.chat_completion(
      messages: [
        {
          role: "system",
          content: "Analyze the sentiment of this social media post.
<!-- TODO: Break into shorter sentences (313 words > 15) --> Return only: positive, negative, or neutral."
        },
        {
          role: "user", 
          content: "#{title}\n\n#{content}"
        }
      ],
      model: "gpt-3.5-turbo"
    )
  end
end

class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :omniauthable, omniauth_providers: [:vipps]
  
  has_many :posts, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :reactions, dependent: :destroy
  has_many :community_memberships, dependent: :destroy
  has_many :communities, through: :community_memberships
  has_one :profile, dependent: :destroy
  
  validates :username, presence: true, uniqueness: true
  validates :city, presence: true
  
  after_create :create_default_profile
  
  def guest?
<!-- TODO: Break into shorter sentences (70 words > 15) --> is_a?(GuestUser)
  end
  
  private
  
  def create_default_profile
    create_profile(bio: "New member of #{city}")
  end
end
```

### Real-time Features Implementation
<!-- TODO: Fix heading hierarchy - level 3 after level 1 -->

```ruby
# StimulusReflex for real-time interactions
class PostReflex < ApplicationReflex
  def upvote
    post = Post.find(element.dataset[:post_id])
    existing_reaction = current_user.reactions.find_by(post: post, kind: 'upvote')
    
    if existing_reaction
      existing_reaction.destroy
    else
      # Remove any existing downvote
      current_user.reactions.where(post: post, kind: 'downvote').destroy_all
      current_user.reactions.create!(post: post, kind: 'upvote')
    end
    
    # Update karma score
    post.update!(karma: post.karma_score)
    
    # Broadcast to all users viewing this post
    cable_ready["post_#{post.id}"].morph(
      selector: "#post-#{post.id}-reactions",
      html: render_reactions(post)
    )
    cable_ready.broadcast
  end
  
  def downvote
    post = Post.find(element.dataset[:post_id])
    existing_reaction = current_user.reactions.find_by(post: post, kind: 'downvote')
    
    if existing_reaction
      existing_reaction.destroy
    else
      # Remove any existing upvote
      current_user.reactions.where(post: post, kind: 'upvote').destroy_all
      current_user.reactions.create!(post: post, kind: 'downvote')
    end
    
    post.update!(karma: post.karma_score)
    
    cable_ready["post_#{post.id}"].morph(
      selector: "#post-#{post.id}-reactions", 
      html: render_reactions(post)
    )
    cable_ready.broadcast
  end
  
  private
  
  def render_reactions(post)
    ApplicationController.render(
      partial: 'posts/reactions',
      locals: { post: post, current_user: current_user }
    )
  end
end

# Real-time comments
class CommentReflex < ApplicationReflex
  def create
    post = Post.find(element.dataset[:post_id])
    content = element.value.strip
    
    return if content.blank?
<!-- TODO: Break into shorter sentences (151 words > 15) --> comment = current_user.comments.build(
      post: post,
      content: content
    )
    
    if comment.save
      # Clear the input
      morph :nothing
      
      # Broadcast new comment to all users
      cable_ready["post_#{post.id}_comments"].insert_adjacent_html(
        selector: "#comments-#{post.id}",
        position: "beforeend",
        html: render_comment(comment)
      )
      cable_ready.broadcast
      
      # Clear input field
      element.value = ""
    end
  end
  
  private
  
  def render_comment(comment)
    ApplicationController.render(
      partial: 'comments/comment',
      locals: { comment: comment }
    )
  end
end
```

### Location-Based Services
<!-- TODO: Fix heading hierarchy - level 3 after level 1 -->

```ruby
# Geolocation service for city-specific content
class GeolocationService
  SUPPORTED_CITIES = {
    "brgen.no" => { lat: 60.3913, lng: 5.3221, radius: 50 },
    "oshlo.no" => { lat: 59.9139, lng: 10.7522, radius: 100 },
    "stholm.se" => { lat: 59.3293, lng: 18.0686, radius: 100 },
    "kbenhvn.dk" => { lat: 55.6761, lng: 12.5683, radius: 80 },
    "hlsinki.fi" => { lat: 60.1699, lng: 24.9384, radius: 80 }
  }.freeze
  
  def self.detect_city(request)
    # Try to detect from subdomain first
    subdomain = request.subdomain
    return subdomain if SUPPORTED_CITIES.key?("#{subdomain}.no")
    
    # Fall back to IP geolocation
    ip_location = geocode_ip(request.remote_ip)
    return closest_city(ip_location) if ip_location
    
    # Default to Bergen
    "brgen"
  end
  
  def self.city_config(city)
    domain = find_domain_for_city(city)
    SUPPORTED_CITIES[domain] || SUPPORTED_CITIES["brgen.no"]
  end
  
  def self.nearby_posts(city, user_lat: nil, user_lng: nil)
    config = city_config(city)
    
    # Use user's exact location if available, otherwise city center
    lat = user_lat || config[:lat]
    lng = user_lng || config[:lng]
    radius = config[:radius]
    
    Post.by_location(lat, lng, radius)
        .includes(:user, :community, :reactions, :comments)
        .order(created_at: :desc)
  end
  
  private
  
  def self.geocode_ip(ip)
    # Integration with IP geolocation service
    # Returns { lat: float, lng: float } or nil
    return nil if ip == "127.0.0.1" # Skip localhost
    
    begin
      response = HTTParty.get("http://ip-api.com/json/#{ip}")
      data = response.parsed_response
      
      if data["status"] == "success"
        { lat: data["lat"], lng: data["lon"] }
      end
    rescue
      nil
    end
  end
  
  def self.closest_city(location)
    min_distance = Float::INFINITY
    closest = "brgen"
    
    SUPPORTED_CITIES.each do |domain, config|
      distance = haversine_distance(
        location[:lat], location[:lng],
        config[:lat], config[:lng]
      )
      
      if distance < min_distance
        min_distance = distance
        closest = domain.split('.').first
      end
    end
    
    closest
  end
  
  def self.haversine_distance(lat1, lng1, lat2, lng2)
    rad_per_deg = Math::PI / 180
    rlat1, rlng1 = lat1 * rad_per_deg, lng1 * rad_per_deg
    rlat2, rlng2 = lat2 * rad_per_deg, lng2 * rad_per_deg
    
    dlat_rad, dlng_rad = rlat2 - rlat1, rlng2 - rlng1
    
    a = Math.sin(dlat_rad/2)**2 + Math.cos(rlat1) * Math.cos(rlat2) * Math.sin(dlng_rad/2)**2
    c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a))
    
    6371 * c # Distance in kilometers
  end
end
```

## Amber Fashion - AI-Enhanced Style Assistant

### Fashion AI Architecture

```ruby
# Fashion recommendation engine
class FashionRecommendationService
  def initialize(user)
    @user = user
    @openai = AI::OpenaiService.new
  end
  
  def analyze_style_preferences
    wardrobe_items = @user.wardrobe_items.includes(:fashion_tags)
    recent_likes = @user.outfit_likes.recent.includes(:outfit)
    
    style_data = {
      colors: extract_color_preferences(wardrobe_items),
      styles: extract_style_preferences(wardrobe_items, recent_likes),
      brands: extract_brand_preferences(wardrobe_items),
      occasions: extract_occasion_preferences(@user.outfit_logs)
    }
    
    generate_style_profile(style_data)
  end
  
  def recommend_outfit(occasion:, weather:, budget: nil)
    style_profile = @user.style_profile || analyze_style_preferences
    
    prompt = build_outfit_prompt(
      style_profile: style_profile,
      occasion: occasion,
      weather: weather,
      budget: budget,
      available_items: @user.wardrobe_items.available
    )
    
    ai_response = @openai.chat_completion(
      messages: [
        {
          role: "system",
          content: "You are a professional fashion stylist.
<!-- TODO: Break into shorter sentences (443 words > 15) --> Create outfit recommendations based on the user's style preferences, available wardrobe items, and the given occasion and weather."
        },
        {
          role: "user",
          content: prompt
        }
      ],
      model: "gpt-4"
    )
    
    parse_outfit_recommendation(ai_response)
  end
  
  def analyze_outfit_photo(image_url)
    # Use OpenAI Vision API to analyze outfit in photo
    response = @openai.chat_completion(
      messages: [
        {
          role: "system",
          content: "Analyze this outfit photo and provide detailed feedback on style, color coordination, fit, and overall aesthetic.
<!-- TODO: Break into shorter sentences (68 words > 15) --> Suggest improvements if any."
        },
        {
          role: "user",
          content: [
            {
              type: "text",
              text: "Please analyze this outfit:"
            },
            {
              type: "image_url",
              image_url: { url: image_url }
            }
          ]
        }
      ],
      model: "gpt-4-vision-preview"
    )
    
    parse_outfit_analysis(response)
  end
  
  private
  
  def extract_color_preferences(items)
    color_counts = items.joins(:fashion_tags)
                       .where(fashion_tags: { category: 'color' })
                       .group('fashion_tags.name')
                       .count
                       
    color_counts.sort_by { |color, count| -count }.first(5).to_h
  end
  
  def build_outfit_prompt(style_profile:, occasion:, weather:, budget:, available_items:)
    <<~PROMPT
      User Style Profile:
      - Preferred Colors: #{style_profile[:colors].keys.join(', ')}
      - Style Types: #{style_profile[:styles].keys.join(', ')}
      - Favorite Brands: #{style_profile[:brands].keys.join(', ')}
      
      Occasion: #{occasion}
      Weather: #{weather[:temperature]}°C, #{weather[:conditions]}
      Budget: #{budget || 'No specific budget'}
      
      Available Wardrobe Items:
      #{format_wardrobe_items(available_items)}
      
      Please recommend a complete outfit including:
      1.
<!-- TODO: Break into shorter sentences (103 words > 15) --> Main clothing items to wear
      2. Accessories and shoes
      3. Color coordination rationale
      4. Alternative options if available
      5. Any missing items to purchase (within budget if specified)
      
      Format the response as JSON with the following structure:
      {
        "outfit": {
          "items": [...],
          "accessories": [...],
          "shoes": "...",
          "rationale": "..."
        },
        "alternatives": [...],
        "shopping_suggestions": [...]
      }
    PROMPT
  end
end

# Wardrobe management models
class WardrobeItem < ApplicationRecord
  belongs_to :user
  has_many :wardrobe_item_tags, dependent: :destroy
  has_many :fashion_tags, through: :wardrobe_item_tags
  has_many :outfit_items, dependent: :destroy
  has_many :outfits, through: :outfit_items
  has_one_attached :photo
  
  validates :name, presence: true
  validates :category, presence: true
  validates :purchase_date, presence: true
  
  scope :available, -> { where(available: true) }
  scope :by_category, ->(category) { where(category: category) }
  scope :by_season, ->(season) { joins(:fashion_tags).where(fashion_tags: { name: season, category: 'season' }) }
  
  enum category: {
    tops: 0,
    bottoms: 1,
    dresses: 2,
    outerwear: 3,
    shoes: 4,
    accessories: 5,
    underwear: 6
  }
  
  def cost_per_wear
    return 0 if times_worn.zero?
<!-- TODO: Break into shorter sentences (128 words > 15) --> purchase_price / times_worn
  end
  
  def sustainability_score
    # Calculate based on brand ethics, material, longevity
    base_score = 50
    base_score += 20 if sustainable_brand?
<!-- TODO: Break into shorter sentences (22 words > 15) --> base_score += 15 if natural_materials? base_score += 10 if times_worn > 20
    base_score += 5 if purchase_date < 1.year.ago
    
    [base_score, 100].min
  end
end

class Outfit < ApplicationRecord
  belongs_to :user
  has_many :outfit_items, dependent: :destroy
  has_many :wardrobe_items, through: :outfit_items
  has_many :outfit_likes, dependent: :destroy
  has_one_attached :photo
  
  validates :occasion, presence: true
  validates :weather_temp, presence: true
  
  scope :for_occasion, ->(occasion) { where(occasion: occasion) }
  scope :recent, -> { where('created_at > ?', 30.days.ago) }
  scope :liked, -> { joins(:outfit_likes).distinct }
  
  def total_cost
    wardrobe_items.sum(:purchase_price)
  end
  
  def average_sustainability_score
    scores = wardrobe_items.map(&:sustainability_score)
    scores.sum / scores.length.to_f
  end
end
```

### Style Analytics Dashboard
<!-- TODO: Fix heading hierarchy - level 3 after level 1 -->

```ruby
# Analytics service for fashion insights
class StyleAnalyticsService
  def initialize(user)
    @user = user
  end
  
  def generate_monthly_report
    outfits_worn = @user.outfit_logs.current_month
    wardrobe_stats = calculate_wardrobe_efficiency
    
    {
      outfits_created: outfits_worn.count,
      favorite_colors: top_colors_this_month,
      most_worn_items: most_worn_items,
      cost_per_wear_improvement: cost_per_wear_trends,
      sustainability_score: average_sustainability_score,
      wardrobe_efficiency: wardrobe_stats,
      recommendations: generate_monthly_recommendations
    }
  end
  
  def wardrobe_gap_analysis
    # Analyze wardrobe for missing essentials
    essential_categories = {
      'business_casual' => ['blazer', 'dress_pants', 'button_shirt', 'dress_shoes'],
      'casual' => ['jeans', 'sneakers', 't_shirt', 'casual_jacket'],
      'formal' => ['suit', 'dress_shirt', 'formal_shoes', 'tie'],
      'workout' => ['athletic_wear', 'sneakers', 'sports_bra']
    }
    
    current_items = @user.wardrobe_items.includes(:fashion_tags)
                         .group_by(&:category)
    
    gaps = {}
    essential_categories.each do |occasion, required_items|
      missing_items = required_items.reject do |item|
        has_item_for_category?(current_items, item)
      end
      
      gaps[occasion] = missing_items unless missing_items.empty?
<!-- TODO: Break into shorter sentences (186 words > 15) --> end
    
    gaps
  end
  
  private
  
  def most_worn_items
    @user.wardrobe_items
         .where('times_worn > 0')
         .order(times_worn: :desc)
         .limit(5)
         .pluck(:name, :times_worn)
  end
  
  def cost_per_wear_trends
    last_month = @user.wardrobe_items
                      .where('purchase_date < ?', 1.month.ago)
                      .average(:purchase_price) / 
                 @user.wardrobe_items
                      .where('purchase_date < ?', 1.month.ago)
                      .average(:times_worn)
                      
    this_month = @user.wardrobe_items
                      .current_month
                      .average(:purchase_price) /
                 @user.wardrobe_items
                      .current_month
                      .average(:times_worn)
    
    improvement = ((last_month - this_month) / last_month * 100).round(2)
    { last_month: last_month, this_month: this_month, improvement: improvement }
  end
end
```

## PostgreSQL Schema Architecture

### Core Database Schema

```sql
-- Extensions for advanced features
CREATE EXTENSION IF NOT EXISTS "vector";
CREATE EXTENSION IF NOT EXISTS "postgis";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
CREATE EXTENSION IF NOT EXISTS "btree_gin";

-- Users and authentication
CREATE TABLE users (
  id BIGSERIAL PRIMARY KEY,
  email VARCHAR(255) NOT NULL UNIQUE,
  username VARCHAR(100) NOT NULL UNIQUE,
  encrypted_password VARCHAR(255) NOT NULL,
  city VARCHAR(100) NOT NULL,
  location GEOGRAPHY(POINT, 4326),
  confirmed_at TIMESTAMP,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_city ON users(city);
CREATE INDEX idx_users_location ON users USING GIST(location);

-- Communities for social features
CREATE TABLE communities (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  city VARCHAR(100) NOT NULL,
  location GEOGRAPHY(POINT, 4326),
  member_count INTEGER DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  
  UNIQUE(name, city)
);

CREATE INDEX idx_communities_city ON communities(city);
CREATE INDEX idx_communities_location ON communities USING GIST(location);
CREATE INDEX idx_communities_search ON communities USING GIN(to_tsvector('english', name || ' ' || description));

-- Posts with vector embeddings for AI recommendations
CREATE TABLE posts (
  id BIGSERIAL PRIMARY KEY,
  title VARCHAR(255) NOT NULL,
  content TEXT NOT NULL,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  community_id BIGINT NOT NULL REFERENCES communities(id) ON DELETE CASCADE,
  location GEOGRAPHY(POINT, 4326),
  karma INTEGER DEFAULT 0,
  embedding VECTOR(1536), -- OpenAI embedding dimension
  sentiment VARCHAR(20),
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_posts_user_id ON posts(user_id);
CREATE INDEX idx_posts_community_id ON posts(community_id);
CREATE INDEX idx_posts_location ON posts USING GIST(location);
CREATE INDEX idx_posts_karma ON posts(karma DESC);
CREATE INDEX idx_posts_created_at ON posts(created_at DESC);
CREATE INDEX idx_posts_embedding ON posts USING ivfflat(embedding vector_cosine_ops) WITH (lists = 100);
CREATE INDEX idx_posts_search ON posts USING GIN(to_tsvector('english', title || ' ' || content));

-- Comments with threading support
CREATE TABLE comments (
  id BIGSERIAL PRIMARY KEY,
  content TEXT NOT NULL,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  post_id BIGINT NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  parent_comment_id BIGINT REFERENCES comments(id) ON DELETE CASCADE,
  depth INTEGER DEFAULT 0,
  path LTREE, -- For efficient tree queries
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_comments_post_id ON comments(post_id);
CREATE INDEX idx_comments_user_id ON comments(user_id);
CREATE INDEX idx_comments_parent ON comments(parent_comment_id);
CREATE INDEX idx_comments_path ON comments USING GIST(path);

-- Reactions for posts and comments
CREATE TABLE reactions (
  id BIGSERIAL PRIMARY KEY,
  kind VARCHAR(20) NOT NULL, -- upvote, downvote, like, love, laugh, angry
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  post_id BIGINT REFERENCES posts(id) ON DELETE CASCADE,
  comment_id BIGINT REFERENCES comments(id) ON DELETE CASCADE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  
  UNIQUE(user_id, post_id, kind),
  UNIQUE(user_id, comment_id, kind),
  CHECK ((post_id IS NOT NULL AND comment_id IS NULL) OR (post_id IS NULL AND comment_id IS NOT NULL))
);

CREATE INDEX idx_reactions_post_id ON reactions(post_id);
CREATE INDEX idx_reactions_comment_id ON reactions(comment_id);
CREATE INDEX idx_reactions_user_id ON reactions(user_id);

-- Fashion/wardrobe items for Amber
CREATE TABLE wardrobe_items (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  category VARCHAR(50) NOT NULL,
  brand VARCHAR(100),
  color VARCHAR(50),
  size VARCHAR(20),
  purchase_price DECIMAL(10,2),
  purchase_date DATE,
  times_worn INTEGER DEFAULT 0,
  available BOOLEAN DEFAULT true,
  sustainability_rating INTEGER, -- 1-100 scale
  care_instructions TEXT,
  embedding VECTOR(1536), -- For style similarity
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_wardrobe_items_user_id ON wardrobe_items(user_id);
CREATE INDEX idx_wardrobe_items_category ON wardrobe_items(category);
CREATE INDEX idx_wardrobe_items_embedding ON wardrobe_items USING ivfflat(embedding vector_cosine_ops) WITH (lists = 100);

-- Outfits combining multiple wardrobe items
CREATE TABLE outfits (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name VARCHAR(255),
  occasion VARCHAR(100),
  weather_temp INTEGER,
  weather_conditions VARCHAR(50),
  total_cost DECIMAL(10,2),
  sustainability_score INTEGER,
  times_worn INTEGER DEFAULT 0,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_outfits_user_id ON outfits(user_id);
CREATE INDEX idx_outfits_occasion ON outfits(occasion);

-- Junction table for outfit items
CREATE TABLE outfit_items (
  id BIGSERIAL PRIMARY KEY,
  outfit_id BIGINT NOT NULL REFERENCES outfits(id) ON DELETE CASCADE,
  wardrobe_item_id BIGINT NOT NULL REFERENCES wardrobe_items(id) ON DELETE CASCADE,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  
  UNIQUE(outfit_id, wardrobe_item_id)
);

-- Marketplace products
CREATE TABLE products (
  id BIGSERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  price DECIMAL(10,2) NOT NULL,
  category VARCHAR(100),
  brand VARCHAR(100),
  vendor_id BIGINT REFERENCES users(id),
  location GEOGRAPHY(POINT, 4326),
  stock_quantity INTEGER DEFAULT 0,
  embedding VECTOR(1536), -- For product recommendations
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_products_category ON products(category);
CREATE INDEX idx_products_vendor_id ON products(vendor_id);
CREATE INDEX idx_products_location ON products USING GIST(location);
CREATE INDEX idx_products_embedding ON products USING ivfflat(embedding vector_cosine_ops) WITH (lists = 100);
CREATE INDEX idx_products_search ON products USING GIN(to_tsvector('english', name || ' ' || description));

-- Performance optimization functions
CREATE OR REPLACE FUNCTION update_community_member_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE communities SET member_count = member_count + 1 WHERE id = NEW.community_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE communities SET member_count = member_count - 1 WHERE id = OLD.community_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Triggers for maintaining data consistency
CREATE TRIGGER update_community_member_count_trigger
  AFTER INSERT OR DELETE ON community_memberships
  FOR EACH ROW EXECUTE FUNCTION update_community_member_count();

-- Function for updating post karma automatically
CREATE OR REPLACE FUNCTION calculate_post_karma(post_id BIGINT)
RETURNS INTEGER AS $$
DECLARE
  upvotes INTEGER;
  downvotes INTEGER;
  comment_count INTEGER;
  karma_score INTEGER;
BEGIN
  SELECT COUNT(*) INTO upvotes FROM reactions WHERE post_id = post_id AND kind = 'upvote';
  SELECT COUNT(*) INTO downvotes FROM reactions WHERE post_id = post_id AND kind = 'downvote';
  SELECT COUNT(*) INTO comment_count FROM comments WHERE post_id = post_id;
  
  karma_score := upvotes - downvotes + (comment_count * 0.5)::INTEGER;
  
  UPDATE posts SET karma = karma_score WHERE id = post_id;
  
  RETURN karma_score;
END;
$$ LANGUAGE plpgsql;

-- Materialized view for trending posts
CREATE MATERIALIZED VIEW trending_posts AS
SELECT 
  p.id,
  p.title,
  p.content,
  p.user_id,
  p.community_id,
  p.karma,
  p.created_at,
  COUNT(r.id) as reaction_count,
  COUNT(c.id) as comment_count,
  -- Trending score based on recency and engagement
  (COUNT(r.id) + COUNT(c.id) * 2) * 
  EXP(-EXTRACT(EPOCH FROM (NOW() - p.created_at)) / 86400.0) as trending_score
FROM posts p
LEFT JOIN reactions r ON p.id = r.post_id
LEFT JOIN comments c ON p.id = c.post_id
WHERE p.created_at > NOW() - INTERVAL '7 days'
GROUP BY p.id, p.title, p.content, p.user_id, p.community_id, p.karma, p.created_at
ORDER BY trending_score DESC;

CREATE UNIQUE INDEX idx_trending_posts_id ON trending_posts(id);
CREATE INDEX idx_trending_posts_score ON trending_posts(trending_score DESC);

-- Refresh the materialized view periodically
CREATE OR REPLACE FUNCTION refresh_trending_posts()
RETURNS void AS $$
BEGIN
  REFRESH MATERIALIZED VIEW CONCURRENTLY trending_posts;
END;
$$ LANGUAGE plpgsql;
```

## Deployment Strategy

### Production Deployment Pipeline

```bash
#!/usr/bin/env zsh
# Production deployment script for Rails ecosystem

set -e

DEPLOY_ENV="${1:-production}"
APP_NAME="${2:-brgen}"
LOG_FILE="/var/log/deploy-${APP_NAME}.log"

log() {
  echo "[$(date -u +%Y-%m-%dT%H:%M:%SZ)] $1" | tee -a "$LOG_FILE"
}

deploy_application() {
  local app_name="$1"
  local app_dir="/home/${app_name}/app"
  
  log "Deploying $app_name to $DEPLOY_ENV"
  
  cd "$app_dir"
  
  # Update application code
  git pull origin main
  
  # Install dependencies
  bundle install --deployment --without development test
  yarn install --frozen-lockfile
  
  # Precompile assets
  RAILS_ENV=production bin/rails assets:precompile
  
  # Run database migrations
  RAILS_ENV=production bin/rails db:migrate
  
  # Refresh materialized views
  RAILS_ENV=production bin/rails runner "
    ActiveRecord::Base.connection.execute('REFRESH MATERIALIZED VIEW CONCURRENTLY trending_posts')
  "
  
  # Restart application server
  if pgrep -f "falcon host" > /dev/null; then
    pkill -f "falcon host"
    sleep 2
  fi
  
  # Start new server process
  cd "$app_dir"
  nohup bundle exec falcon host > "/var/log/${app_name}-server.log" 2>&1 &
  
  # Health check
  sleep 5
  local port=$(grep -o 'port [0-9]*' config/falcon.rb | awk '{print $2}')
  if curl -f "http://localhost:${port}/health" > /dev/null 2>&1; then
    log "$app_name deployed successfully"
  else
    log "ERROR: $app_name health check failed"
    return 1
  fi
}

deploy_all_applications() {
  local apps=(brgen amber pubattorney bsdports hjerterom privcam blognet)
  
  for app in "${apps[@]}"; do
    if [ -d "/home/${app}/app" ]; then
      deploy_application "$app"
    else
      log "Skipping $app - directory not found"
    fi
  done
}

update_nginx_config() {
  log "Updating nginx configuration"
  
  # Generate nginx configuration for all apps
  cat > /etc/nginx/sites-available/rails-ecosystem <<EOF
# Rails ecosystem configuration
upstream rails_apps {
  least_conn;
  
  server 127.0.0.1:3000; # brgen
  server 127.0.0.1:3001; # amber
  server 127.0.0.1:3002; # pubattorney
  server 127.0.0.1:3003; # bsdports
  server 127.0.0.1:3004; # hjerterom
  server 127.0.0.1:3005; # privcam
  server 127.0.0.1:3006; # blognet
}

# Health check endpoint
location /health {
  access_log off;
  return 200 "healthy\n";
  add_header Content-Type text/plain;
}

# Application routing
location / {
  proxy_pass http://rails_apps;
  proxy_set_header Host \$host;
  proxy_set_header X-Real-IP \$remote_addr;
  proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
  proxy_set_header X-Forwarded-Proto \$scheme;
  proxy_connect_timeout 5s;
  proxy_send_timeout 60s;
  proxy_read_timeout 60s;
}
EOF
  
  # Enable the configuration
  ln -sf /etc/nginx/sites-available/rails-ecosystem /etc/nginx/sites-enabled/
  nginx -t && systemctl reload nginx
}

main() {
  if [ "$APP_NAME" = "all" ]; then
    deploy_all_applications
  else
    deploy_application "$APP_NAME"
  fi
  
  update_nginx_config
  
  log "Deployment completed for $APP_NAME"
}

main
```

## Conclusion

This FINAL_RAILS_ECOSYSTEM.md document provides comprehensive, production-ready documentation for a complete Rails application ecosystem.
<!-- TODO: Break into shorter sentences (1491 words > 15) --> The architecture implements modern Rails 8.0+ patterns with advanced features including:

**Technical Excellence:**
- Hotwire integration for real-time user experiences
- Progressive Web App capabilities with offline support  
- Advanced PostgreSQL schema with vector embeddings
- AI-powered content analysis and recommendations
- Geolocation services for hyper-local experiences

**Application Portfolio:**
- **Brgen Platform**: Complete social network with marketplace, dating, music sharing
- **Amber Fashion**: AI-enhanced wardrobe management and style recommendations
- **Banking Revolution**: Next-generation financial services platform
- **Supporting Applications**: BSDPorts, Hjerterom, PrivCam, Blognet

**Production Features:**
- Automated deployment pipelines
- High-performance database optimization
- Real-time monitoring and analytics
- Comprehensive security measures
- Scalable infrastructure architecture

**AI Integration:**
- OpenAI GPT-4 for content generation and analysis
- Vector embeddings for similarity search
- Machine learning-powered recommendations
- Automated content moderation and sentiment analysis

**Next Steps for Implementation:**
1.
<!-- TODO: Break into shorter sentences (138 words > 15) --> Execute shared setup scripts for infrastructure
2. Deploy individual applications using deployment pipeline
3. Configure domain routing and SSL certificates
4. Set up monitoring and alerting systems
5. Initialize AI services and vector databases
6. Perform load testing and performance optimization
7. Implement user onboarding and content seeding
8. Launch progressive rollout to target cities

This ecosystem provides a complete foundation for launching and scaling modern web applications with cutting-edge features and enterprise-grade reliability.
<!-- TODO: Break into shorter sentences (25 words > 15) -->