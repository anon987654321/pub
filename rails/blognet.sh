#!/usr/bin/env zsh

# --- CONFIGURATION ---
app_name="blognet"

# --- GLOBAL SETUP ---
source __shared.sh

# --- INITIALIZATION SECTION ---
initialize_app_directory() {
  initialize_setup "$app_name"
  log "Initialized application directory for $app_name"
}

# --- FRONTEND SETUP SECTION ---
setup_frontend_with_rails() {
  log "Setting up front-end tools integrated with Rails for $app_name"

  # Leveraging Rails with modern frontend tools
  create_rails_app "$app_name"
  bin/rails db:migrate || error_exit "Database migration failed for $app_name"
  log "Rails and frontend tools setup completed for $app_name"

  # Generate views for Home controller using shared scaffold generation
  generate_home_view "$app_name" "Welcome to BlogNet"
  add_seo_metadata "app/views/home/index.html.erb" "BlogNet | Share Your Stories" "Join BlogNet to share your stories, connect with other bloggers, and explore community discussions." || error_exit "Failed to add SEO metadata for Home view"
  add_schema_org_metadata "app/views/home/index.html.erb" || error_exit "Failed to add schema.org metadata for Home view"
}

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
