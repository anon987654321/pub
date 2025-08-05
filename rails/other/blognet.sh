#!/bin/bash

#!/usr/bin/env zsh
set -euo pipefail

# Blognet - AI-Enhanced Blogging Platform  
# Framework v37.3.2 compliant with advanced content management and AI features

APP_NAME="blognet"
BASE_DIR="/home/dev/rails"
BRGEN_IP="46.23.95.45"

source "./__shared.sh"

log "Starting Blognet AI-enhanced blogging platform setup"

setup_full_app "$APP_NAME"

command_exists "ruby"
command_exists "node"
command_exists "psql"
command_exists "redis-server"

# Add AI and content management gems
bundle add ruby-openai
bundle add langchainrb
bundle add friendly_id
bundle add acts_as_tenant
bundle add babosa
bundle add rouge
bundle add redcarpet
bundle install

# Generate enhanced blogging models
bin/rails generate model Blog name:string description:text user:references subdomain:string theme:string
bin/rails generate model Post title:string content:text blog:references user:references published:boolean slug:string tags:text
bin/rails generate model Comment post:references user:references content:text approved:boolean
bin/rails generate model Category name:string description:text blog:references
bin/rails generate model PostCategory post:references category:references
bin/rails generate model Subscription user:references blog:references
bin/rails generate model AIAssistant name:string model_type:string api_key:string blog:references

log "Blognet AI-enhanced blogging platform setup completed"
commit "Set up Blognet with AI content generation and multi-tenant blogging features"

# --- APP-SPECIFIC SETUP SECTION ---
setup_app_specific() {
  log "Setting up $app_name specifics"

  # App-specific functionality
  generate_scaffold "BlogPost" "title:string content:text author:string category:string" || error_exit "Failed to generate scaffold for BlogPosts"
  generate_scaffold "Comment" "content:text user_id:integer blog_post_id:integer" || error_exit "Failed to generate scaffold for Comments"
  generate_scaffold "Category" "name:string description:text" || error_exit "Failed to generate scaffold for Categories"

  # Add rich text editor for blog post creation
  integrate_rich_text_editor "app/views/blog_posts/_form.html.erb" || error_exit "Failed to integrate rich text editor for BlogPosts"
  log "Rich text editor integrated for BlogPosts in $app_name"

  # Generating controllers for managing app-specific features
  generate_controller "BlogPosts" "index show new create edit update destroy" || error_exit "Failed to generate BlogPosts controller"
  generate_controller "Comments" "index show new create edit update destroy" || error_exit "Failed to generate Comments controller"
  generate_controller "Categories" "index show new create edit update destroy" || error_exit "Failed to generate Categories controller"

  # Add common features from shared setup
  apply_common_features "$app_name"
  generate_sitemap "$app_name" || error_exit "Failed to generate sitemap for $app_name"
  configure_dynamic_sitemap_generation || error_exit "Failed to configure dynamic sitemap generation for $app_name"
  log "Sitemap generated for $app_name with dynamic content configuration"
  log "$app_name specifics setup completed with scaffolded models, controllers, and common feature integration"
}

# --- MAIN SECTION ---
main() {
  log "Starting setup for $app_name"
  initialize_app_directory
  setup_frontend_with_rails
  setup_app_specific
  log "Setup completed for $app_name"
}

main "$@"
