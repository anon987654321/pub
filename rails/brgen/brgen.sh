#!/usr/bin/env zsh
# Brgen: Multi-tenant social and marketplace platform with cognitive framework implementation
# Master.json v10.7.0 compliance with zero-trust security and multi-tenancy

set -e
setopt extended_glob null_glob

# === COGNITIVE FRAMEWORK CONFIGURATION ===
APP_NAME="brgen"
BASE_DIR="/home/dev/rails"
BRGEN_IP="46.23.95.45"

# Source enhanced shared functionality
source "../__shared_enhanced.sh"

# === BRGEN-SPECIFIC CONFIGURATION ===
generate_application_code() {
  phase_transition "brgen_code_generation" "Creating multi-tenant social and marketplace platform features"
  
  # Generate models with cognitive constraints (7 concepts max)
  bin/rails generate model Follower follower:references followed:references
  bin/rails generate model Listing title:string description:text price:decimal category:string status:string user:references location:string lat:decimal lng:decimal
  bin/rails generate model City name:string subdomain:string country:string city:string language:string favicon:string analytics:string tld:string
  bin/rails generate model TenantUser user:references city:references role:string active:boolean
  bin/rails generate model MarketplaceTransaction buyer:references seller:references listing:references amount:decimal status:string
  bin/rails generate model CommunityEvent city:references title:string description:text event_date:datetime organizer:references
  bin/rails generate model LocalBusiness city:references name:string description:text address:string phone:string website:string
  
  # Database migrations
  bin/rails db:migrate
  
  # Install additional gems for Brgen
  cat <<EOF >> Gemfile

# Brgen-specific gems
gem "acts_as_tenant", "~> 0.6"
gem "pagy", "~> 8.0"
gem "money-rails", "~> 1.15"
gem "geocoder", "~> 1.8"
gem "friendly_id", "~> 5.5"
gem "image_processing", "~> 1.2"
gem "chronic", "~> 0.10"
EOF
  
  bundle install
  
  # Create cognitive-aware controllers
  cat <<EOF > app/controllers/listings_controller.rb
class ListingsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_listing, only: [:show, :edit, :update, :destroy]
  before_action :check_tenant_access
  
  def index
    @cognitive_load = CognitiveLoadMonitor.new
    @complexity_assessment = @cognitive_load.assess_complexity(
      "Multi-tenant marketplace listings with location filtering and price management"
    )
    
    # Cognitive load management: limit to 7 listings per page
    @pagy, @listings = pagy(filtered_listings.order(created_at: :desc), items: 7)
    @categories = Listing.where(city: current_city).distinct.pluck(:category).compact.sort
    @price_ranges = calculate_price_ranges
  end
  
  def show
    @cognitive_load = CognitiveLoadMonitor.new
    @complexity_assessment = @cognitive_load.assess_complexity(
      "Individual listing with transaction history and location details"
    )
    
    @related_listings = Listing.where(city: current_city)
                               .where(category: @listing.category)
                               .where.not(id: @listing.id)
                               .limit(3)
    
    @transaction_history = @listing.marketplace_transactions
                                   .order(created_at: :desc)
                                   .limit(5)
  end
  
  def new
    @listing = Listing.new
    @cognitive_load = CognitiveLoadMonitor.new
    @complexity_assessment = @cognitive_load.assess_complexity(
      "Listing creation with pricing, location, and image upload"
    )
    
    @categories = Listing.where(city: current_city).distinct.pluck(:category).compact.sort
  end
  
  def create
    @listing = Listing.new(listing_params)
    @listing.user = current_user
    @listing.city = current_city
    @listing.status = "active"
    
    if @listing.save
      # Create tenant association
      TenantUser.find_or_create_by(
        user: current_user,
        city: current_city,
        role: "member",
        active: true
      )
      
      respond_to do |format|
        format.html { redirect_to listings_path, notice: "Listing created successfully!" }
        format.turbo_stream
      end
    else
      @categories = Listing.where(city: current_city).distinct.pluck(:category).compact.sort
      render :new, status: :unprocessable_entity
    end
  end
  
  def edit
    @cognitive_load = CognitiveLoadMonitor.new
    @complexity_assessment = @cognitive_load.assess_complexity(
      "Listing editing with price updates and status management"
    )
    
    @categories = Listing.where(city: current_city).distinct.pluck(:category).compact.sort
  end
  
  def update
    if @listing.update(listing_params)
      respond_to do |format|
        format.html { redirect_to @listing, notice: "Listing updated successfully!" }
        format.turbo_stream
      end
    else
      @categories = Listing.where(city: current_city).distinct.pluck(:category).compact.sort
      render :edit, status: :unprocessable_entity
    end
  end
  
  def destroy
    @listing.destroy
    respond_to do |format|
      format.html { redirect_to listings_path, notice: "Listing deleted successfully!" }
      format.turbo_stream
    end
  end
  
  private
  
  def set_listing
    @listing = Listing.where(city: current_city).find(params[:id])
    unless @listing.user == current_user || current_user&.admin?
      redirect_to listings_path, alert: "Access denied"
    end
  end
  
  def listing_params
    params.require(:listing).permit(:title, :description, :price, :category, :status, :location, :lat, :lng, photos: [])
  end
  
  def filtered_listings
    listings = Listing.where(city: current_city, status: "active")
    listings = listings.where(category: params[:category]) if params[:category].present?
    listings = listings.where("title ILIKE ? OR description ILIKE ?", "%#{params[:search]}%", "%#{params[:search]}%") if params[:search].present?
    
    if params[:price_min].present? || params[:price_max].present?
      price_min = params[:price_min].present? ? params[:price_min].to_f : 0
      price_max = params[:price_max].present? ? params[:price_max].to_f : Float::INFINITY
      listings = listings.where(price: price_min..price_max)
    end
    
    listings
  end
  
  def calculate_price_ranges
    prices = Listing.where(city: current_city, status: "active").pluck(:price).compact
    return [] if prices.empty?
    
    min_price = prices.min
    max_price = prices.max
    range_size = (max_price - min_price) / 5
    
    5.times.map do |i|
      {
        min: (min_price + i * range_size).round(2),
        max: (min_price + (i + 1) * range_size).round(2)
      }
    end
  end
  
  def check_tenant_access
    redirect_to root_path unless current_city
  end
end
EOF
  
  # Create multi-tenant application controller
  cat <<EOF > app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  include CognitiveCompliance
  
  before_action :set_current_city
  before_action :authenticate_user!, except: [:index, :show], unless: :guest_user_allowed?
  
  protect_from_forgery with: :exception
  
  def after_sign_in_path_for(resource)
    root_path
  end
  
  private
  
  def set_current_city
    subdomain = request.subdomain
    @current_city = City.find_by(subdomain: subdomain) if subdomain.present?
    
    unless @current_city
      redirect_to_main_site
      return
    end
    
    # Set tenant for acts_as_tenant
    ActsAsTenant.current_tenant = @current_city
  end
  
  def current_city
    @current_city
  end
  
  def redirect_to_main_site
    redirect_to "https://brgen.com", alert: "Community not found"
  end
  
  def guest_user_allowed?
    controller_name == "home" || 
    (controller_name == "posts" && action_name.in?(["index", "show", "create"])) || 
    (controller_name == "listings" && action_name.in?(["index", "show"]))
  end
end
EOF
  
  # Create multi-tenant models
  cat <<EOF > app/models/listing.rb
class Listing < ApplicationRecord
  belongs_to :user
  belongs_to :city
  has_many :marketplace_transactions, dependent: :destroy
  has_many_attached :photos
  
  validates :title, presence: true, length: { minimum: 5, maximum: 200 }
  validates :description, presence: true, length: { minimum: 10, maximum: 2000 }
  validates :price, presence: true, numericality: { greater_than: 0 }
  validates :category, presence: true
  validates :status, presence: true, inclusion: { in: %w[active sold reserved inactive] }
  validates :location, presence: true
  
  scope :active, -> { where(status: "active") }
  scope :by_category, ->(category) { where(category: category) }
  scope :by_price_range, ->(min, max) { where(price: min..max) }
  scope :recent, -> { order(created_at: :desc) }
  scope :popular, -> { joins(:marketplace_transactions).group(:id).order("COUNT(marketplace_transactions.id) DESC") }
  
  def available?
    status == "active"
  end
  
  def sold?
    status == "sold"
  end
  
  def transaction_count
    marketplace_transactions.count
  end
  
  def interested_buyers
    marketplace_transactions.where(status: "interested").count
  end
  
  def display_price
    "#{price.to_f.round(2)} #{city.currency || 'NOK'}"
  end
  
  def nearby_listings(radius = 10)
    # Simple proximity search (in real implementation, use proper geospatial queries)
    Listing.where(city: city)
           .where.not(id: id)
           .where(status: "active")
           .limit(5)
  end
end
EOF
  
  # Create city model with tenant capabilities
  cat <<EOF > app/models/city.rb
class City < ApplicationRecord
  has_many :listings, dependent: :destroy
  has_many :tenant_users, dependent: :destroy
  has_many :users, through: :tenant_users
  has_many :community_events, dependent: :destroy
  has_many :local_businesses, dependent: :destroy
  
  validates :name, presence: true, uniqueness: true
  validates :subdomain, presence: true, uniqueness: true, format: { with: /\A[a-z0-9]+\z/ }
  validates :country, presence: true
  validates :city, presence: true
  validates :language, presence: true, length: { is: 2 }
  validates :tld, presence: true
  
  scope :active, -> { where(active: true) }
  scope :by_country, ->(country) { where(country: country) }
  scope :by_language, ->(language) { where(language: language) }
  
  def full_domain
    "#{subdomain}.brgen.#{tld}"
  end
  
  def display_name
    "#{name}, #{country}"
  end
  
  def currency
    case country.downcase
    when "norway", "sverige", "denmark"
      "NOK"
    when "sweden"
      "SEK"
    when "denmark"
      "DKK"
    when "iceland"
      "ISK"
    when "finland"
      "EUR"
    when "uk"
      "GBP"
    when "usa"
      "USD"
    else
      "EUR"
    end
  end
  
  def active_listings_count
    listings.active.count
  end
  
  def active_users_count
    tenant_users.where(active: true).count
  end
  
  def recent_activity
    {
      new_listings: listings.where("created_at > ?", 7.days.ago).count,
      new_users: tenant_users.where("created_at > ?", 7.days.ago).count,
      transactions: MarketplaceTransaction.joins(:listing).where(listings: { city: self }).where("created_at > ?", 7.days.ago).count
    }
  end
end
EOF
  
  # Create tenant configuration
  cat <<EOF > config/initializers/tenant.rb
Rails.application.config.middleware.use ActsAsTenant::Middleware

ActsAsTenant.configure do |config|
  config.require_tenant = true
  config.pkey = :city
end
EOF
  
  # Create enhanced home controller
  cat <<EOF > app/controllers/home_controller.rb
class HomeController < ApplicationController
  def index
    @cognitive_load = CognitiveLoadMonitor.new
    @complexity_assessment = @cognitive_load.assess_complexity(
      "Multi-tenant community home with posts, listings, and local business directory"
    )
    
    # Cognitive load management: limit to 7 key elements
    @recent_posts = Post.where(city: current_city).recent.limit(5)
    @featured_listings = Listing.where(city: current_city).active.recent.limit(3)
    @upcoming_events = CommunityEvent.where(city: current_city)
                                     .where("event_date > ?", Time.current)
                                     .order(:event_date)
                                     .limit(3)
    
    @community_stats = {
      total_listings: current_city.active_listings_count,
      active_users: current_city.active_users_count,
      local_businesses: current_city.local_businesses.count,
      recent_activity: current_city.recent_activity
    }
    
    # Flow state tracking for community engagement
    @flow_tracker = FlowStateTracker.new
    @flow_tracker.update({
      "concentration" => 0.8,
      "challenge_skill_balance" => 0.7,
      "clear_goals" => 0.9,
      "immediate_feedback" => 0.8
    })
  end
end
EOF
  
  # Create JavaScript for multi-tenant features
  mkdir -p app/javascript/controllers
  cat <<EOF > app/javascript/controllers/tenant_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["citySelector", "tenantInfo"]
  static values = { currentCity: String, availableCities: Array }
  
  connect() {
    this.updateTenantInfo()
  }
  
  switchCity(event) {
    const selectedCity = event.target.value
    if (selectedCity && selectedCity !== this.currentCityValue) {
      const city = this.availableCitiesValue.find(c => c.subdomain === selectedCity)
      if (city) {
        window.location.href = \`https://\${city.subdomain}.brgen.\${city.tld}\`
      }
    }
  }
  
  updateTenantInfo() {
    if (this.hasTenantInfoTarget) {
      const cityData = this.availableCitiesValue.find(c => c.subdomain === this.currentCityValue)
      if (cityData) {
        this.tenantInfoTarget.innerHTML = \`
          <div class="tenant-info">
            <h3>\${cityData.name}</h3>
            <p>\${cityData.country} • \${cityData.currency}</p>
            <p>Active Users: \${cityData.active_users}</p>
            <p>Active Listings: \${cityData.active_listings}</p>
          </div>
        \`
      }
    }
  }
  
  showCityStats() {
    // Display city statistics modal or panel
    const modal = document.createElement("div")
    modal.className = "city-stats-modal"
    
    const cityData = this.availableCitiesValue.find(c => c.subdomain === this.currentCityValue)
    if (cityData) {
      modal.innerHTML = \`
        <div class="modal-content">
          <h2>\${cityData.name} Community Stats</h2>
          <div class="stats-grid">
            <div class="stat-item">
              <span class="stat-value">\${cityData.active_listings}</span>
              <span class="stat-label">Active Listings</span>
            </div>
            <div class="stat-item">
              <span class="stat-value">\${cityData.active_users}</span>
              <span class="stat-label">Active Users</span>
            </div>
            <div class="stat-item">
              <span class="stat-value">\${cityData.local_businesses}</span>
              <span class="stat-label">Local Businesses</span>
            </div>
          </div>
          <button onclick="this.parentElement.parentElement.remove()">Close</button>
        </div>
      \`
    }
    
    document.body.appendChild(modal)
  }
}
EOF
  
  # Create seed data for cities
  cat <<EOF > db/seeds.rb
# Create cities with cognitive load management (7 main cities + expansions)
cities = [
  { name: "Bergen", subdomain: "brgen", country: "Norway", city: "Bergen", language: "no", tld: "no" },
  { name: "Oslo", subdomain: "oshlo", country: "Norway", city: "Oslo", language: "no", tld: "no" },
  { name: "Trondheim", subdomain: "trndheim", country: "Norway", city: "Trondheim", language: "no", tld: "no" },
  { name: "Stavanger", subdomain: "stvanger", country: "Norway", city: "Stavanger", language: "no", tld: "no" },
  { name: "Tromsø", subdomain: "trmso", country: "Norway", city: "Tromsø", language: "no", tld: "no" },
  { name: "Reykjavík", subdomain: "reykjavk", country: "Iceland", city: "Reykjavík", language: "is", tld: "is" },
  { name: "Copenhagen", subdomain: "kbenhvn", country: "Denmark", city: "Copenhagen", language: "dk", tld: "dk" }
]

admin_user = User.create!(
  email: "admin@brgen.com",
  password: "password",
  password_confirmation: "password"
)

cities.each do |city_attrs|
  city = City.find_or_create_by(subdomain: city_attrs[:subdomain]) do |c|
    c.name = city_attrs[:name]
    c.country = city_attrs[:country]
    c.city = city_attrs[:city]
    c.language = city_attrs[:language]
    c.tld = city_attrs[:tld]
    c.active = true
  end
  
  # Create tenant user relationship
  TenantUser.find_or_create_by(user: admin_user, city: city) do |tu|
    tu.role = "admin"
    tu.active = true
  end
  
  # Create sample listings for each city
  3.times do |i|
    Listing.create!(
      title: "Sample Item #{i + 1} in #{city.name}",
      description: "This is a sample listing for #{city.name}. Great condition and ready for pickup.",
      price: rand(10.0..500.0).round(2),
      category: %w[electronics furniture clothing books sports].sample,
      status: "active",
      location: "#{city.city} City Center",
      lat: 60.0 + rand(-5.0..5.0),
      lng: 5.0 + rand(-5.0..5.0),
      user: admin_user,
      city: city
    )
  end
  
  # Create sample community event
  CommunityEvent.create!(
    city: city,
    title: "Community Meetup",
    description: "Join us for a community gathering in #{city.name}",
    event_date: 1.week.from_now,
    organizer: admin_user
  )
end

puts "✅ Brgen multi-tenant system seeded successfully!"
puts "🏙️ #{City.count} cities created"
puts "📦 #{Listing.count} listings created"
puts "🎉 #{CommunityEvent.count} events created"
puts "👥 #{TenantUser.count} tenant relationships created"
EOF
  
  # Run seeds
  bin/rails db:seed
  
  log "Brgen application code generation completed" "INFO"
}

# Override main to use enhanced installation
main() {
  log "Starting Brgen installation with cognitive framework" "INFO"
  
  # Use enhanced shared installation
  source "../__shared_enhanced.sh"
  
  # Run the main installation process
  if command -v initialize_application > /dev/null 2>&1; then
    # Run enhanced installation
    initialize_application
    setup_rails_application
    setup_database
    setup_cognitive_framework
    setup_authentication
    setup_security
    generate_application_code  # This will use our Brgen-specific implementation
    setup_testing
    finalize_installation
  else
    # Fallback to original installation
    log "Enhanced installation not available, using fallback" "WARN"
    setup_rails_application
    setup_database
    generate_application_code
  fi
}

install_gem "acts_as_tenant"
install_gem "pagy"

bin/rails generate model Follower follower:references followed:references
bin/rails generate scaffold Listing title:string description:text price:decimal category:string status:string user:references location:string lat:decimal lng:decimal photos:attachments
bin/rails generate scaffold City name:string subdomain:string country:string city:string language:string favicon:string analytics:string tld:string

cat <<EOF > app/reflexes/listings_infinite_scroll_reflex.rb
class ListingsInfiniteScrollReflex < InfiniteScrollReflex
  def load_more
    @pagy, @collection = pagy(Listing.where(community: ActsAsTenant.current_tenant).order(created_at: :desc), page: page)
    super
  end
end
EOF

cat <<EOF > app/reflexes/insights_reflex.rb
class InsightsReflex < ApplicationReflex
  def analyze
    posts = Post.where(community: ActsAsTenant.current_tenant)
    titles = posts.map(&:title).join(", ")
    cable_ready.replace(selector: "#insights-output", html: "<div class='insights'>Analyzed: #{titles}</div>").broadcast
  end
end
EOF

cat <<EOF > app/javascript/controllers/mapbox_controller.js
import { Controller } from "@hotwired/stimulus"
import mapboxgl from "mapbox-gl"
import MapboxGeocoder from "mapbox-gl-geocoder"

export default class extends Controller {
  static values = { apiKey: String, listings: Array }

  connect() {
    mapboxgl.accessToken = this.apiKeyValue
    this.map = new mapboxgl.Map({
      container: this.element,
      style: "mapbox://styles/mapbox/streets-v11",
      center: [5.3467, 60.3971], // Bergen
      zoom: 12
    })

    this.map.addControl(new MapboxGeocoder({
      accessToken: this.apiKeyValue,
      mapboxgl: mapboxgl
    }))

    this.map.on("load", () => {
      this.addMarkers()
    })
  }

  addMarkers() {
    this.listingsValue.forEach(listing => {
      new mapboxgl.Marker({ color: "#1a73e8" })
        .setLngLat([listing.lng, listing.lat])
        .setPopup(new mapboxgl.Popup().setHTML(\`<h3>\${listing.title}</h3><p>\${listing.description}</p>\`))
        .addTo(this.map)
    })
  }
}
EOF

cat <<EOF > app/javascript/controllers/insights_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["output"]

  analyze(event) {
    event.preventDefault()
    if (!this.hasOutputTarget) {
      console.error("InsightsController: Output target not found")
      return
    }
    this.outputTarget.innerHTML = "<i class='fas fa-spinner fa-spin' aria-label='<%= t('brgen.analyzing') %>'></i>"
    this.stimulate("InsightsReflex#analyze")
  }
}
EOF

cat <<EOF > config/initializers/tenant.rb
Rails.application.config.middleware.use ActsAsTenant::Middleware
ActsAsTenant.configure do |config|
  config.require_tenant = true
end
EOF

cat <<EOF > app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  before_action :set_tenant
  before_action :authenticate_user!, except: [:index, :show], unless: :guest_user_allowed?

  def after_sign_in_path_for(resource)
    root_path
  end

  private

  def set_tenant
    ActsAsTenant.current_tenant = City.find_by(subdomain: request.subdomain)
    unless ActsAsTenant.current_tenant
      redirect_to root_url(subdomain: false), alert: t("brgen.tenant_not_found")
    end
  end

  def guest_user_allowed?
    controller_name == "home" || 
    (controller_name == "posts" && action_name.in?(["index", "show", "create"])) || 
    (controller_name == "listings" && action_name.in?(["index", "show"]))
  end
end
EOF

cat <<EOF > app/controllers/home_controller.rb
class HomeController < ApplicationController
  def index
    @pagy, @posts = pagy(Post.where(community: ActsAsTenant.current_tenant).order(created_at: :desc), items: 10) unless @stimulus_reflex
    @listings = Listing.where(community: ActsAsTenant.current_tenant).order(created_at: :desc).limit(5)
  end
end
EOF

cat <<EOF > app/controllers/listings_controller.rb
class ListingsController < ApplicationController
  before_action :set_listing, only: [:show, :edit, :update, :destroy]
  before_action :initialize_listing, only: [:index, :new]

  def index
    @pagy, @listings = pagy(Listing.where(community: ActsAsTenant.current_tenant).order(created_at: :desc)) unless @stimulus_reflex
  end

  def show
  end

  def new
  end

  def create
    @listing = Listing.new(listing_params)
    @listing.user = current_user
    @listing.community = ActsAsTenant.current_tenant
    if @listing.save
      respond_to do |format|
        format.html { redirect_to listings_path, notice: t("brgen.listing_created") }
        format.turbo_stream
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @listing.update(listing_params)
      respond_to do |format|
        format.html { redirect_to listings_path, notice: t("brgen.listing_updated") }
        format.turbo_stream
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @listing.destroy
    respond_to do |format|
      format.html { redirect_to listings_path, notice: t("brgen.listing_deleted") }
      format.turbo_stream
    end
  end

  private

  def set_listing
    @listing = Listing.where(community: ActsAsTenant.current_tenant).find(params[:id])
    redirect_to listings_path, alert: t("brgen.not_authorized") unless @listing.user == current_user || current_user&.admin?
  end

  def initialize_listing
    @listing = Listing.new
  end

  def listing_params
    params.require(:listing).permit(:title, :description, :price, :category, :status, :location, :lat, :lng, photos: [])
  end
end
EOF

cat <<EOF > app/views/listings/_listing.html.erb
<%= turbo_frame_tag dom_id(listing) do %>
  <%= tag.article class: "post-card", id: dom_id(listing), role: "article" do %>
    <%= tag.div class: "post-header" do %>
      <%= tag.span t("brgen.posted_by", user: listing.user.email) %>
      <%= tag.span listing.created_at.strftime("%Y-%m-%d %H:%M") %>
    <% end %>
    <%= tag.h2 listing.title %>
    <%= tag.p listing.description %>
    <%= tag.p t("brgen.listing_price", price: number_to_currency(listing.price)) %>
    <%= tag.p t("brgen.listing_location", location: listing.location) %>
    <% if listing.photos.attached? %>
      <% listing.photos.each do |photo| %>
        <%= image_tag photo, style: "max-width: 200px;", alt: t("brgen.listing_photo", title: listing.title) %>
      <% end %>
    <% end %>
    <%= render partial: "shared/vote", locals: { votable: listing } %>
    <%= tag.p class: "post-actions" do %>
      <%= link_to t("brgen.view_listing"), listing_path(listing), "aria-label": t("brgen.view_listing") %>
      <%= link_to t("brgen.edit_listing"), edit_listing_path(listing), "aria-label": t("brgen.edit_listing") if listing.user == current_user || current_user&.admin? %>
      <%= button_to t("brgen.delete_listing"), listing_path(listing), method: :delete, data: { turbo_confirm: t("brgen.confirm_delete") }, form: { data: { turbo_frame: "_top" } }, "aria-label": t("brgen.delete_listing") if listing.user == current_user || current_user&.admin? %>
    <% end %>
  <% end %>
<% end %>
EOF

cat <<EOF > app/views/listings/_form.html.erb
<%= form_with model: listing, local: true, data: { controller: "character-counter form-validation", turbo: true } do |form| %>
  <%= tag.div data: { turbo_frame: "notices" } do %>
    <%= render "shared/notices" %>
  <% end %>
  <% if listing.errors.any? %>
    <%= tag.div role: "alert" do %>
      <%= tag.p t("brgen.errors", count: listing.errors.count) %>
      <%= tag.ul do %>
        <% listing.errors.full_messages.each do |msg| %>
          <%= tag.li msg %>
        <% end %>
      <% end %>
    <% end %>
  <% end %>
  <%= tag.fieldset do %>
    <%= form.label :title, t("Brgen.listing_title"), "aria-required": true %>
    <%= form.text_field :title, required: true, data: { "form-validation-target": "input", action: "input->form-validation#validate" }, title: t("brgen.listing_title_help") %>
    <%= tag.span class: "error-message" data: { "form-validation-target": "error", for: "listing_title" } %>
  <% end %>
  <%= tag.fieldset do %>
    <%= form.label :description, t("brgen.listing_description"), "aria-required": true %>
    <%= form.text_area :description, required: true, data: { "character-counter-target": "input", "textarea-autogrow-target": "input", "form-validation-target": "input", action: "input->character-counter#count input->textarea-autogrow#resize input->form-validation#validate" }, title: t("brgen.listing_description_help") %>
    <%= tag.span data: { "character-counter-target": "count" } %>
    <%= tag.span class: "error-message" data: { "form-validation-target": "error", for: "listing_description" } %>
  <% end %>
  <%= tag.fieldset do %>
    <%= form.label :price, t("brgen.listing_price"), "aria-required": true %>
    <%= form.number_field :price, required: true, step: 0.01, data: { "form-validation-target": "input", action: "input->form-validation#validate" }, title: t("brgen.listing_price_help") %>
    <%= tag.span class: "error-message" data: { "form-validation-target": "error", for: "listing_price" } %>
  <% end %>
  <%= tag.fieldset do %>
    <%= form.label :category, t("brgen.listing_category"), "aria-required": true %>
    <%= form.text_field :category, required: true, data: { "form-validation-target": "input", action: "input->form-validation#validate" }, title: t("brgen.listing_category_help") %>
    <%= tag.span class: "error-message" data: { "form-validation-target": "error", for: "listing_category" } %>
  <% end %>
  <%= tag.fieldset do %>
    <%= form.label :status, t("brgen.listing_status"), "aria-required": true %>
    <%= form.select :status, ["available", "sold"], { prompt: t("brgen.status_prompt") }, required: true %>
    <%= tag.span class: "error-message" data: { "form-validation-target": "error", for: "listing_status" } %>
  <% end %>
  <%= tag.fieldset do %>
    <%= form.label :location, t("brgen.listing_location"), "aria-required": true %>
    <%= form.text_field :location, required: true, data: { "form-validation-target": "input", action: "input->form-validation#validate" }, title: t("brgen.listing_location_help") %>
    <%= tag.span class: "error-message" data: { "form-validation-target": "error", for: "listing_location" } %>
  <% end %>
  <%= tag.fieldset do %>
    <%= form.label :lat, t("brgen.listing_lat"), "aria-required": true %>
    <%= form.number_field :lat, required: true, step: "any", data: { "form-validation-target": "input", action: "input->form-validation#validate" }, title: t("brgen.listing_lat_help") %>
    <%= tag.span class: "error-message" data: { "form-validation-target": "error", for: "listing_lat" } %>
  <% end %>
  <%= tag.fieldset do %>
    <%= form.label :lng, t("brgen.listing_lng"), "aria-required": true %>
    <%= form.number_field :lng, required: true, step: "any", data: { "form-validation-target": "input", action: "input->form-validation#validate" }, title: t("brgen.listing_lng_help") %>
    <%= tag.span class: "error-message" data: { "form-validation-target": "error", for: "listing_lng" } %>
  <% end %>
  <%= tag.fieldset do %>
    <%= form.label :photos, t("brgen.listing_photos") %>
    <%= form.file_field :photos, multiple: true, accept: "image/*", data: { controller: "file-preview", "file-preview-target": "input" } %>
    <%= tag.div data: { "file-preview-target": "preview" }, style: "display: none;" %>
  <% end %>
  <%= form.submit %>
<% end %>
EOF

cat <<EOF > app/views/shared/_header.html.erb
<%= tag.header role: "banner" do %>
  <%= render partial: "${APP_NAME}_logo/logo" %>
<% end %>
EOF

cat <<EOF > app/views/shared/_footer.html.erb
<%= tag.footer role: "contentinfo" do %>
  <%= tag.nav class: "footer-links" aria-label: t("shared.footer_nav") do %>
    <%= link_to "", "https://facebook.com", class: "footer-link fb", "aria-label": "Facebook" %>
    <%= link_to "", "https://twitter.com", class: "footer-link tw", "aria-label": "Twitter" %>
    <%= link_to "", "https://instagram.com", class: "footer-link ig", "aria-label": "Instagram" %>
    <%= link_to t("shared.about"), "#", class: "footer-link text" %>
    <%= link_to t("shared.contact"), "#", class: "footer-link text" %>
    <%= link_to t("shared.terms"), "#", class: "footer-link text" %>
    <%= link_to t("shared.privacy"), "#", class: "footer-link text" %>
  <% end %>
<% end %>
EOF

cat <<EOF > app/views/listings/index.html.erb
<% content_for :title, t("brgen.listings_title") %>
<% content_for :description, t("brgen.listings_description") %>
<% content_for :keywords, t("brgen.listings_keywords", default: "brgen, marketplace, listings, #{ActsAsTenant.current_tenant.name}") %>
<% content_for :schema do %>
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "WebPage",
    "name": "<%= t('brgen.listings_title') %>",
    "description": "<%= t('brgen.listings_description') %>",
    "url": "<%= request.original_url %>",
    "hasPart": [
      <% @listings.each do |listing| %>
      {
        "@type": "Product",
        "name": "<%= listing.title %>",
        "description": "<%= listing.description&.truncate(160) %>",
        "offers": {
          "@type": "Offer",
          "price": "<%= listing.price %>",
          "priceCurrency": "NOK"
        },
        "geo": {
          "@type": "GeoCoordinates",
          "latitude": "<%= listing.lat %>",
          "longitude": "<%= listing.lng %>"
        }
      }<%= "," unless listing == @listings.last %>
      <% end %>
    ]
  }
  </script>
<% end %>
<%= render "shared/header" %>
<%= tag.main role: "main" do %>
  <%= tag.section aria-labelledby: "listings-heading" do %>
    <%= tag.h1 t("brgen.listings_title"), id: "listings-heading" %>
    <%= tag.div data: { turbo_frame: "notices" } do %>
      <%= render "shared/notices" %>
    <% end %>
    <%= link_to t("brgen.new_listing"), new_listing_path, class: "button", "aria-label": t("brgen.new_listing") if current_user %>
    <%= turbo_frame_tag "listings" data: { controller: "infinite-scroll" } do %>
      <% @listings.each do |listing| %>
        <%= render partial: "listings/listing", locals: { listing: listing } %>
      <% end %>
      <%= tag.div id: "sentinel", class: "hidden", data: { reflex: "ListingsInfiniteScroll#load_more", next_page: @pagy.next || 2 } %>
    <% end %>
    <%= tag.button t("brgen.load_more"), id: "load-more", data: { reflex: "click->ListingsInfiniteScroll#load_more", "next-page": @pagy.next || 2, "reflex-root": "#load-more" }, class: @pagy&.next ? "" : "hidden", "aria-label": t("brgen.load_more") %>
  <% end %>
  <%= tag.section aria-labelledby: "search-heading" do %>
    <%= tag.h2 t("brgen.search_title"), id: "search-heading" %>
    <%= tag.div data: { controller: "search", model: "Listing", field: "title" } do %>
      <%= tag.input type: "text", placeholder: t("brgen.search_placeholder"), data: { "search-target": "input", action: "input->search#search" }, "aria-label": t("brgen.search_listings") %>
      <%= tag.div id: "search-results", data: { "search-target": "results" } %>
      <%= tag.div id: "reset-link" %>
    <% end %>
  <% end %>
<% end %>
<%= render "shared/footer" %>
EOF

cat <<EOF > app/views/cities/index.html.erb
<% content_for :title, t("brgen.cities_title") %>
<% content_for :description, t("brgen.cities_description") %>
<% content_for :keywords, t("brgen.cities_keywords", default: "brgen, cities, community") %>
<% content_for :schema do %>
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "WebPage",
    "name": "<%= t('brgen.cities_title') %>",
    "description": "<%= t('brgen.cities_description') %>",
    "url": "<%= request.original_url %>"
  }
  </script>
<% end %>
<%= render "shared/header" %>
<%= tag.main role: "main" do %>
  <%= tag.section aria-labelledby: "cities-heading" do %>
    <%= tag.h1 t("brgen.cities_title"), id: "cities-heading" %>
    <%= tag.div data: { turbo_frame: "notices" } do %>
      <%= render "shared/notices" %>
    <% end %>
    <%= link_to t("brgen.new_city"), new_city_path, class: "button", "aria-label": t("brgen.new_city") if current_user %>
    <%= turbo_frame_tag "cities" do %>
      <% @cities.each do |city| %>
        <%= render partial: "cities/city", locals: { city: city } %>
      <% end %>
    <% end %>
  <% end %>
<% end %>
<%= render "shared/footer" %>
EOF

cat <<EOF > app/views/cities/_city.html.erb
<%= turbo_frame_tag dom_id(city) do %>
  <%= tag.article class: "post-card", id: dom_id(city), role: "article" do %>
    <%= tag.h2 city.name %>
    <%= tag.p t("brgen.city_country", country: city.country) %>
    <%= tag.p t("brgen.city_name", city: city.city) %>
    <%= tag.p class: "post-actions" do %>
      <%= link_to t("brgen.view_posts"), "http://#{city.subdomain}.brgen.#{city.tld}/posts", "aria-label": t("brgen.view_posts") %>
      <%= link_to t("brgen.view_listings"), "http://#{city.subdomain}.brgen.#{city.tld}/listings", "aria-label": t("brgen.view_listings") %>
      <%= link_to t("brgen.edit_city"), edit_city_path(city), "aria-label": t("brgen.edit_city") if current_user %>
      <%= button_to t("brgen.delete_city"), city_path(city), method: :delete, data: { turbo_confirm: t("brgen.confirm_delete") }, form: { data: { turbo_frame: "_top" } }, "aria-label": t("brgen.delete_city") if current_user %>
    <% end %>
  <% end %>
<% end %>
EOF

cat <<EOF > app/views/home/index.html.erb
<% content_for :title, t("brgen.home_title") %>
<% content_for :description, t("brgen.home_description") %>
<% content_for :keywords, t("brgen.home_keywords", default: "brgen, community, marketplace, #{ActsAsTenant.current_tenant.name}") %>
<% content_for :schema do %>
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "WebPage",
    "name": "<%= t('brgen.home_title') %>",
    "description": "<%= t('brgen.home_description') %>",
    "url": "<%= request.original_url %>",
    "publisher": {
      "@type": "Organization",
      "name": "Brgen",
      "logo": {
        "@type": "ImageObject",
        "url": "<%= image_url('brgen_logo.svg') %>"
      }
    }
  }
  </script>
<% end %>
<%= render "shared/header" %>
<%= tag.main role: "main" do %>
  <%= tag.section aria-labelledby: "post-heading" do %>
    <%= tag.h1 t("brgen.post_title"), id: "post-heading" %>
    <%= tag.div data: { turbo_frame: "notices" } do %>
      <%= render "shared/notices" %>
    <% end %>
    <%= render partial: "posts/form", locals: { post: Post.new } %>
  <% end %>
  <%= tag.section aria-labelledby: "map-heading" do %>
    <%= tag.h2 t("brgen.map_title"), id: "map-heading" %>
    <%= tag.div id: "map" data: { controller: "mapbox", "mapbox-api-key-value": ENV["MAPBOX_API_KEY"], "mapbox-listings-value": @listings.to_json } %>
  <% end %>
  <%= tag.section aria-labelledby: "search-heading" do %>
    <%= tag.h2 t("brgen.search_title"), id: "search-heading" %>
    <%= tag.div data: { controller: "search", model: "Post", field: "title" } do %>
      <%= tag.input type: "text", placeholder: t("brgen.search_placeholder"), data: { "search-target": "input", action: "input->search#search" }, "aria-label": t("brgen.search_posts") %>
      <%= tag.div id: "search-results", data: { "search-target": "results" } %>
      <%= tag.div id: "reset-link" %>
    <% end %>
  <% end %>
  <%= tag.section aria-labelledby: "posts-heading" do %>
    <%= tag.h2 t("brgen.posts_title"), id: "posts-heading" %>
    <%= turbo_frame_tag "posts" data: { controller: "infinite-scroll" } do %>
      <% @posts.each do |post| %>
        <%= render partial: "posts/post", locals: { post: post } %>
      <% end %>
      <%= tag.div id: "sentinel", class: "hidden", data: { reflex: "PostsInfiniteScroll#load_more", next_page: @pagy.next || 2 } %>
    <% end %>
    <%= tag.button t("brgen.load_more"), id: "load-more", data: { reflex: "click->PostsInfiniteScroll#load_more", "next-page": @pagy.next || 2, "reflex-root": "#load-more" }, class: @pagy&.next ? "" : "hidden", "aria-label": t("brgen.load_more") %>
  <% end %>
  <%= tag.section aria-labelledby: "listings-heading" do %>
    <%= tag.h2 t("brgen.listings_title"), id: "listings-heading" %>
    <%= link_to t("brgen.new_listing"), new_listing_path, class: "button", "aria-label": t("brgen.new_listing") if current_user %>
    <%= turbo_frame_tag "listings" data: { controller: "infinite-scroll" } do %>
      <% @listings.each do |listing| %>
        <%= render partial: "listings/listing", locals: { listing: listing } %>
      <% end %>
      <%= tag.div id: "sentinel", class: "hidden", data: { reflex: "ListingsInfiniteScroll#load_more", next_page: @pagy.next || 2 } %>
    <% end %>
    <%= tag.button t("brgen.load_more"), id: "load-more", data: { reflex: "click->ListingsInfiniteScroll#load_more", "next-page": @pagy.next || 2, "reflex-root": "#load-more" }, class: @pagy&.next ? "" : "hidden", "aria-label": t("brgen.load_more") %>
  <% end %>
  <%= render partial: "shared/chat" %>
  <%= tag.section aria-labelledby: "insights-heading" do %>
    <%= tag.h2 t("brgen.insights_title"), id: "insights-heading" %>
    <%= tag.div data: { controller: "insights" } do %>
      <%= tag.button t("brgen.get_insights"), data: { action: "click->insights#analyze" }, "aria-label": t("brgen.get_insights") %>
      <%= tag.div id: "insights-output", data: { "insights-target": "output" } %>
    <% end %>
  <% end %>
<% end %>
<%= render "shared/footer" %>
EOF

cat <<EOF > config/locales/en.yml
en:
  brgen:
    home_title: "Brgen - Connect Locally"
    home_description: "Join your local Brgen community to share posts, trade items, and connect with neighbors in #{ActsAsTenant.current_tenant&.name || 'your city'}."
    home_keywords: "brgen, community, marketplace, #{ActsAsTenant.current_tenant&.name}"
    post_title: "Share What's Happening"
    posts_title: "Community Posts"
    posts_description: "Explore posts from your #{ActsAsTenant.current_tenant&.name} community."
    new_post_title: "Create a Post"
    new_post_description: "Share an update or idea with your community."
    edit_post_title: "Edit Your Post"
    edit_post_description: "Update your community post."
    post_created: "Post shared successfully."
    post_updated: "Post updated successfully."
    post_deleted: "Post removed successfully."
    listing_title: "Item Title"
    listing_description: "Item Description"
    listing_price: "Price"
    listing_category: "Category"
    listing_status: "Status"
    listing_location: "Location"
    listing_lat: "Latitude"
    listing_lng: "Longitude"
    listing_photos: "Photos"
    listing_title_help: "Enter a clear title for your item."
    listing_description_help: "Describe your item in detail."
    listing_price_help: "Set the price for your item."
    listing_category_help: "Choose a category for your item."
    listing_status_help: "Select the current status of your item."
    listing_location_help: "Specify the pickup location."
    listing_lat_help: "Enter the latitude for the location."
    listing_lng_help: "Enter the longitude for the location."
    listings_title: "Marketplace Listings"
    listings_description: "Browse items for sale in #{ActsAsTenant.current_tenant&.name}."
    new_listing_title: "Create a Listing"
    new_listing_description: "Add an item to the marketplace."
    edit_listing_title: "Edit Listing"
    edit_listing_description: "Update your marketplace listing."
    listing_created: "Listing created successfully."
    listing_updated: "Listing updated successfully."
    listing_deleted: "Listing removed successfully."
    listing_photo: "Photo of %{title}"
    cities_title: "Brgen Cities"
    cities_description: "Explore Brgen communities across the globe."
    new_city_title: "Add a City"
    new_city_description: "Create a new Brgen community."
    edit_city_title: "Edit City"
    edit_city_description: "Update city details."
    city_title: "%{name} Community"
    city_description: "Connect with the Brgen community in %{name}."
    city_created: "City added successfully."
    city_updated: "City updated successfully."
    city_deleted: "City removed successfully."
    city_name: "City Name"
    city_subdomain: "Subdomain"
    city_country: "Country"
    city_city: "City"
    city_language: "Language"
    city_tld: "TLD"
    city_favicon: "Favicon"
    city_analytics: "Analytics"
    city_name_help: "Enter the full city name."
    city_subdomain_help: "Choose a unique subdomain."
    city_country_help: "Specify the country."
    city_city_help: "Enter the city name."
    city_language_help: "Set the primary language code."
    city_tld_help: "Enter the top-level domain."
    city_favicon_help: "Optional favicon URL."
    city_analytics_help: "Optional analytics ID."
    tenant_not_found: "Community not found."
    not_authorized: "You are not authorized to perform this action."
    errors: "%{count} error(s) prevented this action."
    logo_alt: "Brgen Logo"
    logo_title: "Brgen Community Platform"
    map_title: "Local Listings Map"
    search_title: "Search Community"
    search_placeholder: "Search posts or listings..."
    status_prompt: "Select status"
    confirm_delete: "Are you sure you want to delete this?"
    analyzing: "Analyzing..."
    insights_title: "Community Insights"
    get_insights: "Get Insights"
    posted_by: "Posted by %{user}"
    view_post: "View Post"
    edit_post: "Edit Post"
    delete_post: "Delete Post"
    view_listing: "View Listing"
    edit_listing: "Edit Listing"
    delete_listing: "Delete Listing"
    new_post: "New Post"
    new_listing: "New Listing"
    new_city: "New City"
    edit_city: "Edit City"
    delete_city: "Delete City"
    view_posts: "View Posts"
    view_listings: "View Listings"
EOF

cat <<EOF > db/seeds.rb
cities = [
  { name: "Bergen", subdomain: "brgen", country: "Norway", city: "Bergen", language: "no", tld: "no" },
  { name: "Oslo", subdomain: "oshlo", country: "Norway", city: "Oslo", language: "no", tld: "no" },
  { name: "Trondheim", subdomain: "trndheim", country: "Norway", city: "Trondheim", language: "no", tld: "no" },
  { name: "Stavanger", subdomain: "stvanger", country: "Norway", city: "Stavanger", language: "no", tld: "no" },
  { name: "Tromsø", subdomain: "trmso", country: "Norway", city: "Tromsø", language: "no", tld: "no" },
  { name: "Longyearbyen", subdomain: "longyearbyn", country: "Norway", city: "Longyearbyen", language: "no", tld: "no" },
  { name: "Reykjavík", subdomain: "reykjavk", country: "Iceland", city: "Reykjavík", language: "is", tld: "is" },
  { name: "Copenhagen", subdomain: "kbenhvn", country: "Denmark", city: "Copenhagen", language: "dk", tld: "dk" },
  { name: "Stockholm", subdomain: "stholm", country: "Sweden", city: "Stockholm", language: "se", tld: "se" },
  { name: "Gothenburg", subdomain: "gtebrg", country: "Sweden", city: "Gothenburg", language: "se", tld: "se" },
  { name: "Malmö", subdomain: "mlmoe", country: "Sweden", city: "Malmö", language: "se", tld: "se" },
  { name: "Helsinki", subdomain: "hlsinki", country: "Finland", city: "Helsinki", language: "fi", tld: "fi" },
  { name: "London", subdomain: "lndon", country: "UK", city: "London", language: "en", tld: "uk" },
  { name: "Cardiff", subdomain: "cardff", country: "UK", city: "Cardiff", language: "en", tld: "uk" },
  { name: "Manchester", subdomain: "mnchester", country: "UK", city: "Manchester", language: "en", tld: "uk" },
  { name: "Birmingham", subdomain: "brmingham", country: "UK", city: "Birmingham", language: "en", tld: "uk" },
  { name: "Liverpool", subdomain: "lverpool", country: "UK", city: "Liverpool", language: "en", tld: "uk" },
  { name: "Edinburgh", subdomain: "edinbrgh", country: "UK", city: "Edinburgh", language: "en", tld: "uk" },
  { name: "Glasgow", subdomain: "glasgw", country: "UK", city: "Glasgow", language: "en", tld: "uk" },
  { name: "Amsterdam", subdomain: "amstrdam", country: "Netherlands", city: "Amsterdam", language: "nl", tld: "nl" },
  { name: "Rotterdam", subdomain: "rottrdam", country: "Netherlands", city: "Rotterdam", language: "nl", tld: "nl" },
  { name: "Utrecht", subdomain: "utrcht", country: "Netherlands", city: "Utrecht", language: "nl", tld: "nl" },
  { name: "Brussels", subdomain: "brssels", country: "Belgium", city: "Brussels", language: "nl", tld: "be" },
  { name: "Zürich", subdomain: "zrich", country: "Switzerland", city: "Zurich", language: "de", tld: "ch" },
  { name: "Vaduz", subdomain: "lchtenstein", country: "Liechtenstein", city: "Vaduz", language: "de", tld: "li" },
  { name: "Frankfurt", subdomain: "frankfrt", country: "Germany", city: "Frankfurt", language: "de", tld: "de" },
  { name: "Warsaw", subdomain: "wrsawa", country: "Poland", city: "Warsaw", language: "pl", tld: "pl" },
  { name: "Gdańsk", subdomain: "gdnsk", country: "Poland", city: "Gdańsk", language: "pl", tld: "pl" },
  { name: "Bordeaux", subdomain: "brdeaux", country: "France", city: "Bordeaux", language: "fr", tld: "fr" },
  { name: "Marseille", subdomain: "mrseille", country: "France", city: "Marseille", language: "fr", tld: "fr" },
  { name: "Milan", subdomain: "mlan", country: "Italy", city: "Milan", language: "it", tld: "it" },
  { name: "Lisbon", subdomain: "lsbon", country: "Portugal", city: "Lisbon", language: "pt", tld: "pt" },
  { name: "Los Angeles", subdomain: "lsangeles", country: "USA", city: "Los Angeles", language: "en", tld: "org" },
  { name: "New York", subdomain: "newyrk", country: "USA", city: "New York", language: "en", tld: "org" },
  { name: "Chicago", subdomain: "chcago", country: "USA", city: "Chicago", language: "en", tld: "org" },
  { name: "Houston", subdomain: "houstn", country: "USA", city: "Houston", language: "en", tld: "org" },
  { name: "Dallas", subdomain: "dllas", country: "USA", city: "Dallas", language: "en", tld: "org" },
  { name: "Austin", subdomain: "austn", country: "USA", city: "Austin", language: "en", tld: "org" },
  { name: "Portland", subdomain: "prtland", country: "USA", city: "Portland", language: "en", tld: "org" },
  { name: "Minneapolis", subdomain: "mnnesota", country: "USA", city: "Minneapolis", language: "en", tld: "org" }
]

cities.each do |city|
  City.find_or_create_by(subdomain: city[:subdomain]) do |c|
    c.name = city[:name]
    c.country = city[:country]
    c.city = city[:city]
    c.language = city[:language]
    c.tld = city[:tld]
  end
end

puts "Seeded #{cities.count} cities."
EOF

mkdir -p app/views/brgen_logo

cat <<EOF > app/views/brgen_logo/_logo.html.erb
<%= tag.svg xmlns: "http://www.w3.org/2000/svg", viewBox: "0 0 100 50", role: "img", class: "logo", "aria-label": t("brgen.logo_alt") do %>
  <%= tag.title t("brgen.logo_title", default: "Brgen Logo") %>
  <%= tag.text x: "50", y: "30", "text-anchor": "middle", "font-family": "Helvetica, Arial, sans-serif", "font-size": "20", fill: "#1a73e8" do %>Brgen<% end %>
<% end %>
EOF

commit "Brgen core setup complete: Multi-tenant social and marketplace platform"

log "Brgen core setup complete. Run 'bin/falcon-host' to start on OpenBSD."

# Change Log:
# - Aligned with master.json v6.5.0: Two-space indents, double quotes, heredocs, Strunk & White comments
# - Used Rails 8 conventions, Hotwire, Turbo Streams, Stimulus Reflex, I18n, and Falcon
# - Leveraged bin/rails generate scaffold for Listings and Cities to reduce manual code
# - Extracted header and footer into shared partials
# - Reused anonymous posting and live chat from __shared.sh
# - Added Mapbox for listings, live search, and infinite scroll
# - Fixed tenant TLDs with .org for US cities
# - Ensured NNG, SEO, schema data, and minimal flat design compliance
# - Finalized for unprivileged user on OpenBSD 7.5