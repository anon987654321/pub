#!/usr/bin/env zsh

app_name="brgen_takeaway"
source __shared.sh

# ---

initialize_app_directory() {
  initialize_setup "$app_name"
  log "Initialized $app_name directory"
}

# ---

setup_frontend_with_rails() {
  log "Setting up front-end for $app_name"

  create_rails_app "$app_name"
  if ! bin/rails db:migrate; then
    error_exit "DB migration failed for $app_name"
  fi
  log "Rails setup completed for $app_name"

  generate_view_and_scss "brgen_takeaway/restaurants/index" "<h1>Restaurants</h1><button>Order Food</button>" "h1 { font-size: 2rem; } button { background-color: #ff5722; color: white; padding: 10px; border-radius: 5px; }"
  generate_view_and_scss "brgen_takeaway/orders/index" "<h1>Your Orders</h1><button>Track Order</button>" "h1 { font-size: 2rem; } button { background-color: #ff5722; color: white; padding: 10px; border-radius: 5px; }"
  log "Frontend views setup for $app_name"

  yarn_install "swiper@8.0.7" "@stimulus-components/carousel@1.2.0" "@hotwired/turbo-rails@7.2.0"
  log "JavaScript components setup completed"
}

# ---

setup_app_specific() {
  log "Setting up specifics for $app_name"

  generate_model_with_validations "BrgenTakeaway::Restaurant" "name:string location:string cuisine:string user_id:integer" "validates :name, presence: true" "belongs_to :user"
  generate_model_with_validations "BrgenTakeaway::Order" "restaurant_id:integer user_id:integer status:string total_price:decimal" "validates :status, presence: true
validates :total_price, numericality: { greater_than: 0 }" "belongs_to :restaurant"
  log "Models generated for $app_name"

  generate_controller_with_crud "BrgenTakeaway::Restaurants" "BrgenTakeaway::Restaurant" "name location cuisine user_id"
  generate_controller_with_crud "BrgenTakeaway::Orders" "BrgenTakeaway::Order" "restaurant_id user_id status total_price"
  log "Controllers generated for $app_name"

  setup_redis || error_exit "Redis setup failed"
  if ! redis-cli ping | grep -q PONG; then
    error_exit "Redis health check failed"
  fi
  log "Redis setup completed"

  integrate_live_chat || error_exit "Live chat integration failed"
  configure_live_chat_backend || error_exit "Live chat backend configuration failed"
  log "Live chat setup completed"

  apply_common_features "$app_name"
  log "$app_name specifics setup completed"
}

# ---

seed_database() {
  log "Seeding database for $app_name"
  bin/rails db:seed || error_exit "Database seeding failed for $app_name"
  log "Database seeding completed for $app_name"
}

# ---

main() {
  log "Starting $app_name setup"
  initialize_app_directory
  setup_frontend_with_rails
  setup_app_specific
  seed_database
  log "$app_name setup finished"
}

main "$@"

