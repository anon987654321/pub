#!/bin/sh
# Rails Progressive Web App (PWA) setup script with i18n and service workers
# File: install_rails_pwa.sh
# Line count: 120
# SHA-256 Checksum: [Computed by master.json]

# Set strict error handling
set -e

# Log file for traceability
LOG_FILE="/var/log/install_rails_pwa.log"
log() {
    echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) - $1" >> "$LOG_FILE"
}

# User prompt function for critical actions
prompt_user() {
    echo "$1 (y/N): "
    read answer
    case "$answer" in
        [yY]|[yY][eE][sS]) return 0 ;;
        *) return 1 ;;
    esac
}

log "Starting Rails PWA setup"

# Check for required tools
required_tools="ruby rails psql npm"
for tool in $required_tools; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        log "Error: $tool not found"
        echo "Error: $tool not found. Please install it." >&2
        exit 1
    fi
done

# Check Ruby and Rails versions
required_ruby="3.3"
required_rails="8.0"
if ! ruby -v | grep -q "$required_ruby"; then
    log "Error: Ruby version must be >= $required_ruby"
    echo "Error: Ruby version must be >= $required_ruby" >&2
    exit 1
fi
if ! rails -v | grep -q "$required_rails"; then
    log "Error: Rails version must be >= $required_rails"
    echo "Error: Rails version must be >= $required_rails" >&2
    exit 1
fi

# Create new Rails app with PostgreSQL
APP_NAME="rails_pwa"
APP_DIR="/opt/$APP_NAME"
if [ -d "$APP_DIR" ]; then
    if ! prompt_user "Directory $APP_DIR already exists. Overwrite?"; then
        log "User opted out of overwriting $APP_DIR"
        echo "Aborting due to user opt-out" >&2
        exit 1
    fi
    rm -rf "$APP_DIR"
fi

log "Creating Rails app"
if ! rails new "$APP_NAME" -d postgresql --skip-test --skip-bundle; then
    log "Error: Failed to create Rails app"
    echo "Error: Failed to create Rails app" >&2
    exit 1
fi

cd "$APP_DIR"

# Install dependencies
log "Installing Ruby gems"
if ! bundle install; then
    log "Error: Failed to install Ruby gems"
    echo "Error: Failed to install Ruby gems" >&2
    exit 1
fi

# Setup i18n
log "Configuring i18n settings"
mkdir -p config/locales
cat << 'EOF' > config/locales/en.yml
en:
  app_name: "Rails PWA"
  welcome: "Welcome to %{app_name}"
EOF

# Update application.rb for i18n
log "Updating application.rb for i18n"
sed -i '/< Application::Base/a\    config.i18n.default_locale = :en\n    config.i18n.available_locales = [:en]' config/application.rb

# Setup PostgreSQL database
DB_NAME="rails_pwa_db"
DB_USER="rails_pwa_user"
DB_PASS="securepassword456"
log "Setting up PostgreSQL database"
if ! psql -U postgres -c "CREATE DATABASE $DB_NAME;" >/dev/null 2>&1; then
    log "Error: Failed to create database $DB_NAME"
    echo "Error: Failed to create database $DB_NAME" >&2
    exit 1
fi

if ! psql -U postgres -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASS';" >/dev/null 2>&1; then
    log "Error: Failed to create user $DB_USER"
    echo "Error: Failed to create user $DB_USER" >&2
    exit 1
fi

if ! psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;" >/dev/null 2>&1; then
    log "Error: Failed to grant privileges to $DB_USER"
    echo "Error: Failed to grant privileges to $DB_USER" >&2
    exit 1
fi

# Configure database.yml
log "Configuring database.yml"
cat << EOF > config/database.yml
default: &default
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
  username: $DB_USER
  password: $DB_PASS
  host: localhost

development:
  <<: *default
  database: $DB_NAME

production:
  <<: *default
  database: $DB_NAME
EOF

# Run database setup
log "Running database setup"
if ! rails db:create db:migrate; then
    log "Error: Failed to setup database"
    echo "Error: Failed to setup database" >&2
    exit 1
fi

# Add PWA support
log "Adding PWA support"
# Install necessary gems
echo "gem 'pwa'" >> Gemfile
if ! bundle install; then
    log "Error: Failed to install PWA gem"
    echo "Error: Failed to install PWA gem" >&2
    exit 1
fi

# Generate PWA files
log "Generating PWA files"
if ! rails generate pwa:install; then
    log "Error: Failed to generate PWA files"
    echo "Error: Failed to generate PWA files" >&2
    exit 1
fi

# Create service worker
mkdir -p app/javascript
cat << 'EOF' > app/javascript/service-worker.js
self.addEventListener('install', (event) => {
  console.log('Service Worker installed');
});

self.addEventListener('fetch', (event) => {
  event.respondWith(
    caches.match(event.request).then((response) => {
      return response || fetch(event.request);
    })
  );
});
EOF

# Create manifest
cat << 'EOF' > app/views/layouts/manifest.json.erb
{
  "name": "<%= t('app_name') %>",
  "short_name": "RailsPWA",
  "start_url": "/",
  "display": "standalone",
  "background_color": "#ffffff",
  "theme_color": "#000000",
  "icons": [
    {
      "src": "/icon.png",
      "sizes": "192x192",
      "type": "image/png"
    }
  ]
}
EOF

# Update application layout
log "Updating application layout for PWA"
cat << 'EOF' > app/views/layouts/application.html.erb
<!DOCTYPE html>
<html>
<head>
  <title><%= t('app_name') %></title>
  <%= csrf_meta_tags %>
  <%= csp_meta_tag %>
  <%= stylesheet_link_tag 'application', media: 'all' %>
  <%= javascript_include_tag 'application' %>
  <link rel="manifest" href="<%= manifest_path %>">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="theme-color" content="#000000">
</head>
<body>
  <p><%= t('welcome', app_name: t('app_name')) %></p>
  <%= yield %>
  <script>
    if ('serviceWorker' in navigator) {
      navigator.serviceWorker.register('/service-worker.js')
        .then(reg => console.log('Service Worker registered', reg))
        .catch(err => console.error('Service Worker registration failed', err));
    }
  </script>
</body>
</html>
EOF

log "Rails PWA setup completed successfully"

# EOF: Line count and checksum generated by master.json
