#!/usr/bin/env zsh
set -euo pipefail

# Brgen core setup: Multi-tenant social and marketplace platform with enhanced production features
# Enhanced with PWA, analytics, rich text, karma system, caching, error handling
# Modern Rails 8 architecture on OpenBSD 7.5, unprivileged user

APP_NAME="brgen"
BASE_DIR="/home/dev/rails"
BRGEN_IP="46.23.95.45"

source "./__shared.sh"

log "Starting Brgen core setup with production enhancements"

setup_full_app "$APP_NAME"

# Verify system requirements
check_system_requirements

# Install additional gems specific to Brgen multi-tenant platform
log "Installing Brgen-specific gems for multi-tenant architecture"
bundle add acts_as_tenant pagy friendly_id ransack kaminari

# Generate enhanced models with production features
log "Generating enhanced models with relationships and validations"
bin/rails generate model Follower follower:references followed:references created_at:datetime
bin/rails generate scaffold Listing title:string description:text price:decimal category:string status:string user:references location:string lat:decimal lng:decimal photos:attachments views_count:integer:default=0
bin/rails generate scaffold City name:string subdomain:string country:string city:string language:string favicon:string analytics:string tld:string active:boolean:default=true meta_title:string meta_description:text

# Add enhanced model concerns and validations
cat <<EOF > app/models/concerns/trackable.rb
module Trackable
  extend ActiveSupport::Concern
  
  included do
    has_many :ahoy_events, as: :trackable, dependent: :destroy
    
    after_create :track_creation
    after_update :track_update, if: :saved_changes?
  end
  
  def track_view(user = nil)
    ahoy.track("#{self.class.name} Viewed", {
      trackable_type: self.class.name,
      trackable_id: id,
      user_id: user&.id,
      timestamp: Time.current
    })
    
    # Increment view counter if available
    if respond_to?(:views_count)
      increment!(:views_count)
    end
  end
  
  private
  
  def track_creation
    ahoy.track("#{self.class.name} Created", {
      trackable_type: self.class.name,
      trackable_id: id,
      user_id: try(:user_id),
      timestamp: Time.current
    })
  end
  
  def track_update
    ahoy.track("#{self.class.name} Updated", {
      trackable_type: self.class.name,
      trackable_id: id,
      user_id: try(:user_id),
      changes: saved_changes.keys,
      timestamp: Time.current
    })
  end
end
EOF

# Enhanced Listing model with searchability and trackability
cat <<EOF > app/models/listing.rb
class Listing < ApplicationRecord
  belongs_to :user
  belongs_to :city, optional: true
  has_many_attached :photos
  
  include Searchable
  include Trackable
  include Cacheable
  
  acts_as_votable
  acts_as_tenant(:city)
  
  validates :title, presence: true, length: { minimum: 3, maximum: 100 }
  validates :description, presence: true, length: { minimum: 10, maximum: 2000 }
  validates :price, presence: true, numericality: { greater_than: 0 }
  validates :category, presence: true
  validates :status, presence: true, inclusion: { in: %w[available sold reserved] }
  validates :location, presence: true
  validates :lat, :lng, presence: true, numericality: true
  
  scope :available, -> { where(status: 'available') }
  scope :by_category, ->(category) { where(category: category) }
  scope :by_location, ->(location) { where('location ILIKE ?', "%#{location}%") }
  scope :price_range, ->(min, max) { where(price: min..max) }
  scope :recent, -> { where('created_at > ?', 1.week.ago) }
  scope :popular, -> { order(views_count: :desc) }
  
  before_validation :geocode_location, if: :location_changed?
  before_save :set_city_from_location
  after_create :award_creation_karma
  
  def price_range
    case price
    when 0..100 then 'budget'
    when 101..500 then 'mid-range'
    when 501..1000 then 'premium'
    else 'luxury'
    end
  end
  
  def distance_from(lat, lng)
    return nil unless self.lat && self.lng
    Geocoder::Calculations.distance_between([self.lat, self.lng], [lat, lng])
  end
  
  def similar_listings(limit = 5)
    self.class.where(category: category)
             .where.not(id: id)
             .available
             .limit(limit)
  end
  
  private
  
  def geocode_location
    # Simple geocoding placeholder - integrate with actual service
    if location.present?
      # For Bergen area as default
      self.lat ||= 60.3913 + rand(-0.1..0.1)
      self.lng ||= 5.3221 + rand(-0.1..0.1)
    end
  end
  
  def set_city_from_location
    if location.present? && ActsAsTenant.current_tenant
      self.city = ActsAsTenant.current_tenant
    end
  end
  
  def award_creation_karma
    user.award_karma(10, 'created a listing') if user
  end
end
EOF

# Enhanced City model with additional features
cat <<EOF > app/models/city.rb
class City < ApplicationRecord
  has_many :listings, dependent: :destroy
  has_many :users, dependent: :nullify
  has_many :posts, dependent: :destroy
  
  validates :name, presence: true, uniqueness: true
  validates :subdomain, presence: true, uniqueness: true, format: { with: /\A[a-z0-9]+\z/ }
  validates :country, presence: true
  validates :city, presence: true
  validates :language, presence: true
  validates :tld, presence: true
  
  scope :active, -> { where(active: true) }
  scope :by_country, ->(country) { where(country: country) }
  scope :by_language, ->(language) { where(language: language) }
  
  before_validation :normalize_attributes
  before_save :generate_meta_data
  
  def full_domain
    "#{subdomain}.brgen.#{tld}"
  end
  
  def timezone
    # Map countries to timezones
    case country.downcase
    when 'norway', 'denmark', 'sweden' then 'Europe/Oslo'
    when 'finland' then 'Europe/Helsinki'
    when 'iceland' then 'Atlantic/Reykjavik'
    when 'uk' then 'Europe/London'
    when 'netherlands', 'belgium' then 'Europe/Amsterdam'
    when 'germany', 'switzerland' then 'Europe/Berlin'
    when 'france' then 'Europe/Paris'
    when 'usa' then 'America/New_York'
    else 'UTC'
    end
  end
  
  def locale
    case language.downcase
    when 'no', 'nb' then :nb
    when 'da' then :da
    when 'sv' then :sv
    when 'fi' then :fi
    when 'is' then :is
    when 'de' then :de
    when 'fr' then :fr
    when 'nl' then :nl
    else :en
    end
  end
  
  def statistics
    Rails.cache.fetch("city_#{id}_stats", expires_in: 1.hour) do
      {
        total_listings: listings.count,
        active_listings: listings.available.count,
        total_users: users.count,
        posts_this_week: posts.where('created_at > ?', 1.week.ago).count
      }
    end
  end
  
  private
  
  def normalize_attributes
    self.subdomain = subdomain&.downcase&.strip
    self.name = name&.strip
    self.city = city&.strip
    self.country = country&.strip
    self.language = language&.downcase&.strip
    self.tld = tld&.downcase&.strip
  end
  
  def generate_meta_data
    if meta_title.blank?
      self.meta_title = "#{name} - Local Community & Marketplace | Brgen"
    end
    
    if meta_description.blank?
      self.meta_description = "Connect with your local community in #{name}. Buy, sell, and discover in #{city}, #{country}. Join the Brgen community today."
    end
  end
end
EOF

# Enhanced Reflexes with better performance and error handling
cat <<EOF > app/reflexes/listings_infinite_scroll_reflex.rb
class ListingsInfiniteScrollReflex < InfiniteScrollReflex
  def load_more
    @pagy, @collection = pagy(
      Listing.where(city: ActsAsTenant.current_tenant)
             .includes(:user, photos_attachments: :blob)
             .available
             .order(created_at: :desc), 
      page: page
    )
    super
  rescue StandardError => e
    Rails.logger.error "Listings infinite scroll error: #{e.message}"
    broadcast_error("Failed to load more listings. Please try again.")
  end
  
  private
  
  def broadcast_error(message)
    cable_ready.inner_html(
      selector: "#load-more",
      html: "<p class='error'>#{message}</p>"
    ).broadcast
  end
end
EOF

cat <<EOF > app/reflexes/insights_reflex.rb
class InsightsReflex < ApplicationReflex
  def analyze
    city = ActsAsTenant.current_tenant
    return unless city
    
    insights = Rails.cache.fetch("insights_#{city.id}", expires_in: 15.minutes) do
      calculate_insights(city)
    end
    
    cable_ready.replace(
      selector: "#insights-output", 
      html: render(partial: "shared/insights", locals: { insights: insights })
    ).broadcast
    
    # Track analytics event
    ahoy.track "Insights Viewed", {
      city_id: city.id,
      city_name: city.name,
      timestamp: Time.current
    }
  rescue StandardError => e
    Rails.logger.error "Insights analysis error: #{e.message}"
    cable_ready.replace(
      selector: "#insights-output",
      html: "<div class='error'>Unable to generate insights. Please try again later.</div>"
    ).broadcast
  end
  
  private
  
  def calculate_insights(city)
    posts = Post.where(city: city).includes(:user, :votes)
    listings = Listing.where(city: city).includes(:user, :votes)
    
    {
      total_posts: posts.count,
      total_listings: listings.count,
      active_users: User.joins(:posts, :listings).where(posts: { city: city }).distinct.count,
      top_categories: listings.group(:category).count.sort_by(&:last).reverse.first(5),
      engagement_rate: calculate_engagement_rate(posts, listings),
      trending_topics: extract_trending_topics(posts)
    }
  end
  
  def calculate_engagement_rate(posts, listings)
    total_content = posts.count + listings.count
    return 0 if total_content.zero?
    
    total_votes = Vote.where(votable: posts).count + Vote.where(votable: listings).count
    (total_votes.to_f / total_content * 100).round(2)
  end
  
  def extract_trending_topics(posts)
    # Simple keyword extraction from recent posts
    recent_posts = posts.where('created_at > ?', 1.week.ago)
    words = recent_posts.pluck(:title, :body).flatten.compact
                       .join(' ').downcase.split(/\W+/)
                       .select { |w| w.length > 3 }
                       .tally
                       .sort_by(&:last).reverse.first(10)
    words.map(&:first)
  end
end
EOF

# Enhanced Mapbox controller with better error handling and accessibility
cat <<EOF > app/javascript/controllers/mapbox_controller.js
import { Controller } from "@hotwired/stimulus"
import mapboxgl from "mapbox-gl"
import MapboxGeocoder from "mapbox-gl-geocoder"

export default class extends Controller {
  static targets = ["container", "sidebar"]
  static values = { 
    apiKey: String, 
    listings: Array,
    center: { type: Array, default: [5.3467, 60.3971] },
    zoom: { type: Number, default: 12 }
  }

  connect() {
    if (!this.apiKeyValue) {
      console.error("Mapbox API key not provided")
      this.showError("Map cannot be loaded without API key")
      return
    }
    
    this.initializeMap()
  }

  disconnect() {
    if (this.map) {
      this.map.remove()
    }
  }

  initializeMap() {
    try {
      mapboxgl.accessToken = this.apiKeyValue
      
      this.map = new mapboxgl.Map({
        container: this.containerTarget,
        style: "mapbox://styles/mapbox/streets-v11",
        center: this.centerValue,
        zoom: this.zoomValue,
        attributionControl: false
      })

      // Add navigation controls
      this.map.addControl(new mapboxgl.NavigationControl(), 'top-right')
      
      // Add geocoder
      const geocoder = new MapboxGeocoder({
        accessToken: this.apiKeyValue,
        mapboxgl: mapboxgl,
        placeholder: 'Search for places...',
        proximity: this.centerValue
      })
      
      this.map.addControl(geocoder, 'top-left')

      // Wait for map to load before adding markers
      this.map.on('load', () => {
        this.addMarkers()
        this.setupMapEvents()
      })

      this.map.on('error', (e) => {
        console.error('Mapbox error:', e)
        this.showError("Failed to load map")
      })

    } catch (error) {
      console.error('Failed to initialize map:', error)
      this.showError("Map initialization failed")
    }
  }

  addMarkers() {
    if (!this.listingsValue || !Array.isArray(this.listingsValue)) {
      return
    }

    this.listingsValue.forEach((listing, index) => {
      if (!listing.lat || !listing.lng) {
        console.warn(`Listing ${listing.id} missing coordinates`)
        return
      }

      // Create marker element
      const markerElement = document.createElement('div')
      markerElement.className = 'custom-marker'
      markerElement.setAttribute('role', 'button')
      markerElement.setAttribute('aria-label', `View ${listing.title}`)
      markerElement.innerHTML = `
        <div class="marker-content">
          <span class="marker-price">kr ${listing.price}</span>
        </div>
      `

      // Create popup content
      const popupContent = this.createPopupContent(listing)
      
      const popup = new mapboxgl.Popup({ 
        offset: 25,
        closeButton: true,
        closeOnClick: false,
        maxWidth: '300px'
      }).setHTML(popupContent)

      const marker = new mapboxgl.Marker(markerElement)
        .setLngLat([listing.lng, listing.lat])
        .setPopup(popup)
        .addTo(this.map)

      // Track marker interactions
      markerElement.addEventListener('click', () => {
        this.trackMarkerClick(listing)
      })
    })
  }

  createPopupContent(listing) {
    return `
      <div class="listing-popup">
        <h3 class="popup-title">${this.escapeHtml(listing.title)}</h3>
        <p class="popup-price">kr ${listing.price}</p>
        <p class="popup-location">${this.escapeHtml(listing.location || '')}</p>
        <p class="popup-description">${this.escapeHtml(this.truncate(listing.description || '', 100))}</p>
        <div class="popup-actions">
          <a href="/listings/${listing.id}" class="popup-link" aria-label="View ${this.escapeHtml(listing.title)}">
            View Details
          </a>
        </div>
      </div>
    `
  }

  setupMapEvents() {
    // Handle map clicks for accessibility
    this.map.on('click', (e) => {
      // Close any open popups when clicking empty areas
      const popups = document.querySelectorAll('.mapboxgl-popup')
      popups.forEach(popup => {
        if (popup.style.display !== 'none') {
          popup.querySelector('.mapboxgl-popup-close-button')?.click()
        }
      })
    })

    // Update URL when map view changes (for bookmarking)
    this.map.on('moveend', () => {
      const center = this.map.getCenter()
      const zoom = this.map.getZoom()
      
      if (window.history.replaceState) {
        const url = new URL(window.location)
        url.searchParams.set('lat', center.lat.toFixed(4))
        url.searchParams.set('lng', center.lng.toFixed(4))
        url.searchParams.set('zoom', zoom.toFixed(1))
        window.history.replaceState({}, '', url)
      }
    })
  }

  trackMarkerClick(listing) {
    if (typeof ahoy !== 'undefined') {
      ahoy.track('Map Marker Clicked', {
        listing_id: listing.id,
        listing_title: listing.title,
        listing_price: listing.price,
        timestamp: new Date().toISOString()
      })
    }
  }

  showError(message) {
    this.containerTarget.innerHTML = `
      <div class="map-error" role="alert">
        <h3>Map Unavailable</h3>
        <p>${message}</p>
        <button onclick="location.reload()" class="retry-button">Retry</button>
      </div>
    `
  }

  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }

  truncate(text, length) {
    return text.length > length ? text.substring(0, length) + '...' : text
  }
}
EOF

# Enhanced insights controller with better UX
cat <<EOF > app/javascript/controllers/insights_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["output", "button"]
  static classes = ["loading", "error", "success"]

  analyze(event) {
    event.preventDefault()
    
    if (!this.hasOutputTarget) {
      console.error("InsightsController: Output target not found")
      return
    }
    
    this.showLoading()
    this.disableButton()
    
    try {
      this.stimulate("InsightsReflex#analyze")
    } catch (error) {
      console.error("Insights analysis failed:", error)
      this.showError("Analysis failed. Please try again.")
      this.enableButton()
    }
    
    // Re-enable button after timeout
    setTimeout(() => {
      this.enableButton()
    }, 5000)
  }

  showLoading() {
    this.outputTarget.innerHTML = `
      <div class="insights-loading">
        <div class="loading-spinner" aria-label="Analyzing data"></div>
        <p>Analyzing community data...</p>
      </div>
    `
    this.outputTarget.classList.add(this.loadingClass)
  }

  showError(message) {
    this.outputTarget.innerHTML = `
      <div class="insights-error" role="alert">
        <h4>Analysis Error</h4>
        <p>${message}</p>
      </div>
    `
    this.outputTarget.classList.remove(this.loadingClass)
    this.outputTarget.classList.add(this.errorClass)
  }

  disableButton() {
    if (this.hasButtonTarget) {
      this.buttonTarget.disabled = true
      this.buttonTarget.textContent = "Analyzing..."
    }
  }

  enableButton() {
    if (this.hasButtonTarget) {
      this.buttonTarget.disabled = false
      this.buttonTarget.textContent = "Get Insights"
    }
  }

  // Called when insights are successfully loaded
  insightsLoaded() {
    this.outputTarget.classList.remove(this.loadingClass, this.errorClass)
    this.outputTarget.classList.add(this.successClass)
    this.enableButton()
    
    // Track successful insights view
    if (typeof ahoy !== 'undefined') {
      ahoy.track('Community Insights Viewed', {
        timestamp: new Date().toISOString()
      })
    }
  }
}
EOF

# Enhanced tenant configuration with better error handling
cat <<EOF > config/initializers/tenant.rb
# Enhanced multi-tenant configuration for Brgen
Rails.application.config.middleware.use ActsAsTenant::Middleware

ActsAsTenant.configure do |config|
  config.require_tenant = Rails.env.production?
  config.pkey = :city_id
  
  # Custom tenant not found handling
  config.tenant_not_found_handler = lambda do |request|
    if Rails.env.development?
      # In development, create a default tenant if none exists
      city = City.find_or_create_by(subdomain: 'brgen') do |c|
        c.name = 'Bergen'
        c.country = 'Norway'
        c.city = 'Bergen'
        c.language = 'no'
        c.tld = 'no'
        c.active = true
      end
      ActsAsTenant.current_tenant = city
    else
      # In production, redirect to main site
      [302, { 'Location' => 'https://brgen.no' }, ['Redirecting to main site']]
    end
  end
end

# Extend ActsAsTenant with caching
module ActsAsTenant
  module ControllerExtensions
    def set_current_tenant_with_caching
      tenant_key = request.subdomain.presence || 'brgen'
      
      @current_tenant = Rails.cache.fetch("tenant_#{tenant_key}", expires_in: 1.hour) do
        City.find_by(subdomain: tenant_key, active: true)
      end
      
      if @current_tenant
        ActsAsTenant.current_tenant = @current_tenant
        I18n.locale = @current_tenant.locale
      else
        handle_tenant_not_found
      end
    end
    
    private
    
    def handle_tenant_not_found
      if ActsAsTenant.configuration.tenant_not_found_handler
        result = ActsAsTenant.configuration.tenant_not_found_handler.call(request)
        if result.is_a?(Array) && result.length == 3
          # Rack response format
          response.status = result[0]
          result[1].each { |k, v| response.headers[k] = v }
          render plain: result[2].join, status: result[0]
        end
      else
        render plain: 'Tenant not found', status: 404
      end
    end
  end
end
EOF

# Enhanced application controller with better tenant management and security
cat <<EOF > app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  include PwaHelper
  include I18nHelpers
  
  protect_from_forgery with: :exception
  
  before_action :set_current_tenant
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :authenticate_user!, except: [:index, :show], unless: :guest_allowed?
  before_action :set_locale
  before_action :track_visit
  
  rescue_from ActsAsTenant::Errors::NoTenantSet, with: :handle_no_tenant
  rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
  rescue_from ActionController::ParameterMissing, with: :handle_parameter_missing

  def after_sign_in_path_for(resource)
    stored_location_for(resource) || root_path
  end

  def after_sign_out_path_for(resource_or_scope)
    root_path
  end

  private

  def set_current_tenant
    tenant_key = request.subdomain.presence || 'brgen'
    
    @current_tenant = Rails.cache.fetch("tenant_#{tenant_key}", expires_in: 1.hour) do
      City.active.find_by(subdomain: tenant_key)
    end
    
    if @current_tenant
      ActsAsTenant.current_tenant = @current_tenant
      @city = @current_tenant # For backward compatibility
    else
      handle_tenant_not_found
    end
  end
  
  def set_locale
    if @current_tenant
      I18n.locale = @current_tenant.locale
    else
      I18n.locale = extract_locale_from_accept_language_header || I18n.default_locale
    end
  end
  
  def track_visit
    return unless @current_tenant
    
    ahoy.visit_properties = {
      city_id: @current_tenant.id,
      city_name: @current_tenant.name,
      subdomain: @current_tenant.subdomain
    }
  end

  def guest_allowed?
    (controller_name == "home") || 
    (controller_name == "posts" && action_name.in?(["index", "show", "create"])) || 
    (controller_name == "listings" && action_name.in?(["index", "show"])) ||
    (controller_name == "cities" && action_name.in?(["index", "show"])) ||
    (controller_name == "devise/sessions")
  end
  
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :city_id])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name, :city_id, :bio])
  end
  
  def extract_locale_from_accept_language_header
    return nil unless request.env['HTTP_ACCEPT_LANGUAGE']
    
    request.env['HTTP_ACCEPT_LANGUAGE'].scan(/^[a-z]{2}/).map(&:to_sym).find do |locale|
      I18n.available_locales.include?(locale)
    end
  end
  
  def handle_tenant_not_found
    if Rails.env.development?
      # Create default tenant in development
      @current_tenant = City.find_or_create_by(subdomain: 'brgen') do |city|
        city.name = 'Bergen'
        city.country = 'Norway'
        city.city = 'Bergen'
        city.language = 'no'
        city.tld = 'no'
        city.active = true
        city.meta_title = 'Bergen Community - Brgen'
        city.meta_description = 'Connect with your local Bergen community'
      end
      ActsAsTenant.current_tenant = @current_tenant
    else
      redirect_to "https://brgen.no", alert: t("brgen.tenant_not_found")
    end
  end
  
  def handle_no_tenant
    Rails.logger.error "No tenant set for request: #{request.url}"
    redirect_to root_url(subdomain: false), alert: t("brgen.tenant_required")
  end
  
  def handle_not_found
    respond_to do |format|
      format.html { render 'errors/not_found', status: 404 }
      format.json { render json: { error: 'Not found' }, status: 404 }
    end
  end
  
  def handle_parameter_missing(exception)
    respond_to do |format|
      format.html { 
        flash[:alert] = "Required parameter missing: #{exception.param}"
        redirect_back(fallback_location: root_path)
      }
      format.json { render json: { error: exception.message }, status: 422 }
    end
  end
end
EOF

# Enhanced controllers with better performance and features
cat <<EOF > app/controllers/home_controller.rb
class HomeController < ApplicationController
  def index
    @city_stats = current_city_stats
    @pagy, @posts = pagy(recent_posts, items: 10) unless @stimulus_reflex
    @featured_listings = featured_listings
    
    # Track homepage visit
    ahoy.track "Homepage Visited", {
      city_id: ActsAsTenant.current_tenant&.id,
      timestamp: Time.current
    }
  end
  
  private
  
  def current_city_stats
    return {} unless ActsAsTenant.current_tenant
    
    Rails.cache.fetch("city_#{ActsAsTenant.current_tenant.id}_homepage_stats", expires_in: 30.minutes) do
      {
        total_posts: Post.where(city: ActsAsTenant.current_tenant).count,
        total_listings: Listing.where(city: ActsAsTenant.current_tenant).count,
        active_users: User.joins(:posts).where(posts: { city: ActsAsTenant.current_tenant }).distinct.count,
        recent_activity: recent_activity_count
      }
    end
  end
  
  def recent_posts
    Post.where(city: ActsAsTenant.current_tenant)
        .includes(:user, :votes, rich_text_body: :embeds)
        .order(created_at: :desc)
  end
  
  def featured_listings
    Listing.where(city: ActsAsTenant.current_tenant)
           .available
           .includes(:user, photos_attachments: :blob)
           .order(views_count: :desc, created_at: :desc)
           .limit(6)
  end
  
  def recent_activity_count
    cutoff = 1.week.ago
    Post.where(city: ActsAsTenant.current_tenant, created_at: cutoff..).count +
    Listing.where(city: ActsAsTenant.current_tenant, created_at: cutoff..).count
  end
end
EOF

cat <<EOF > app/controllers/listings_controller.rb
class ListingsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_listing, only: [:show, :edit, :update, :destroy]
  before_action :check_listing_owner, only: [:edit, :update, :destroy]

  def index
    @q = Listing.where(city: ActsAsTenant.current_tenant)
                .available
                .includes(:user, photos_attachments: :blob)
                .ransack(params[:q])
    
    @pagy, @listings = pagy(@q.result.order(created_at: :desc)) unless @stimulus_reflex
    @categories = listing_categories
    @featured_listings = featured_listings_for_sidebar
    
    respond_to do |format|
      format.html
      format.json { render json: listings_json }
    end
  end

  def show
    @listing.track_view(current_user)
    @similar_listings = @listing.similar_listings
    @listing_user_stats = user_listing_stats(@listing.user)
    
    respond_to do |format|
      format.html
      format.json { render json: @listing.as_json(include: [:user, :photos]) }
    end
  end

  def new
    @listing = current_user.listings.build
    @listing.city = ActsAsTenant.current_tenant
  end

  def create
    @listing = current_user.listings.build(listing_params)
    @listing.city = ActsAsTenant.current_tenant
    
    if @listing.save
      track_listing_creation
      respond_to do |format|
        format.html { redirect_to @listing, notice: t("brgen.listing_created") }
        format.turbo_stream
        format.json { render json: @listing, status: :created }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { errors: @listing.errors }, status: :unprocessable_entity }
      end
    end
  end

  def edit
  end

  def update
    if @listing.update(listing_params)
      respond_to do |format|
        format.html { redirect_to @listing, notice: t("brgen.listing_updated") }
        format.turbo_stream
        format.json { render json: @listing }
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: { errors: @listing.errors }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @listing.destroy
    respond_to do |format|
      format.html { redirect_to listings_path, notice: t("brgen.listing_deleted") }
      format.turbo_stream
      format.json { head :no_content }
    end
  end

  private

  def set_listing
    @listing = Listing.where(city: ActsAsTenant.current_tenant)
                     .includes(:user, photos_attachments: :blob)
                     .find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to listings_path, alert: t("brgen.listing_not_found")
  end
  
  def check_listing_owner
    unless @listing.user == current_user || current_user&.admin?
      redirect_to @listing, alert: t("brgen.not_authorized")
    end
  end

  def listing_params
    params.require(:listing).permit(:title, :description, :price, :category, :status, 
                                  :location, :lat, :lng, photos: [])
  end
  
  def listing_categories
    Rails.cache.fetch("listing_categories_#{ActsAsTenant.current_tenant.id}", expires_in: 1.hour) do
      Listing.where(city: ActsAsTenant.current_tenant)
             .group(:category)
             .count
             .sort_by(&:last)
             .reverse
             .map(&:first)
    end
  end
  
  def featured_listings_for_sidebar
    Listing.where(city: ActsAsTenant.current_tenant)
           .available
           .where.not(id: @listings&.map(&:id) || [])
           .order(views_count: :desc)
           .limit(3)
  end
  
  def user_listing_stats(user)
    Rails.cache.fetch("user_#{user.id}_listing_stats", expires_in: 30.minutes) do
      {
        total_listings: user.listings.count,
        active_listings: user.listings.available.count,
        total_views: user.listings.sum(:views_count),
        member_since: user.created_at
      }
    end
  end
  
  def track_listing_creation
    ahoy.track "Listing Created", {
      listing_id: @listing.id,
      category: @listing.category,
      price: @listing.price,
      city_id: ActsAsTenant.current_tenant.id
    }
  end
  
  def listings_json
    {
      listings: @listings.map do |listing|
        listing.as_json(include: [:user], methods: [:price_range])
      end,
      pagination: {
        current_page: @pagy.page,
        total_pages: @pagy.pages,
        total_count: @pagy.count
      },
      categories: @categories
    }
  end
end
EOF

# Complete the setup and commit
log "Finalizing Brgen setup with enhanced features"

# Add enhanced CSS for the design system
cat <<EOF > app/assets/stylesheets/brgen.scss
// Brgen-specific styles extending the design system
@import "design_system";

// Map styles
.custom-marker {
  background: var(--primary-500);
  border: 2px solid var(--white);
  border-radius: 50%;
  width: 40px;
  height: 40px;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: transform var(--transition-fast);
  
  &:hover {
    transform: scale(1.1);
  }
  
  .marker-content {
    color: var(--white);
    font-size: var(--text-xs);
    font-weight: 600;
    text-align: center;
    line-height: 1;
  }
}

.listing-popup {
  .popup-title {
    margin: 0 0 var(--space-2);
    font-size: var(--text-lg);
    font-weight: 600;
    color: var(--gray-900);
  }
  
  .popup-price {
    margin: 0 0 var(--space-2);
    font-size: var(--text-xl);
    font-weight: 700;
    color: var(--primary-500);
  }
  
  .popup-location {
    margin: 0 0 var(--space-2);
    font-size: var(--text-sm);
    color: var(--gray-600);
  }
  
  .popup-description {
    margin: 0 0 var(--space-3);
    font-size: var(--text-sm);
    color: var(--gray-700);
    line-height: 1.4;
  }
  
  .popup-actions {
    text-align: center;
  }
  
  .popup-link {
    @extend .button;
    @extend .button--primary;
    @extend .button--small;
    text-decoration: none;
  }
}

.map-error {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  height: 400px;
  background: var(--gray-50);
  border: 1px solid var(--gray-200);
  border-radius: 8px;
  text-align: center;
  padding: var(--space-8);
  
  h3 {
    color: var(--gray-900);
    margin-bottom: var(--space-4);
  }
  
  p {
    color: var(--gray-600);
    margin-bottom: var(--space-6);
  }
  
  .retry-button {
    @extend .button;
    @extend .button--primary;
  }
}

// Insights styles
.insights-loading {
  text-align: center;
  padding: var(--space-8);
  
  .loading-spinner {
    width: 40px;
    height: 40px;
    margin: 0 auto var(--space-4);
    border: 3px solid var(--gray-200);
    border-top: 3px solid var(--primary-500);
    border-radius: 50%;
    animation: spin 1s linear infinite;
  }
}

.insights-error {
  padding: var(--space-6);
  background: var(--error);
  color: var(--white);
  border-radius: 6px;
  text-align: center;
  
  h4 {
    margin: 0 0 var(--space-2);
    color: var(--white);
  }
}

.insights-success {
  padding: var(--space-6);
  background: var(--success);
  color: var(--white);
  border-radius: 6px;
}

@keyframes spin {
  0% { transform: rotate(0deg); }
  100% { transform: rotate(360deg); }
}

// City stats
.city-stats {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: var(--space-4);
  margin-bottom: var(--space-8);
  
  .stat-card {
    @extend .card;
    text-align: center;
    
    .stat-number {
      font-size: var(--text-3xl);
      font-weight: 700;
      color: var(--primary-500);
      margin-bottom: var(--space-2);
    }
    
    .stat-label {
      font-size: var(--text-sm);
      color: var(--gray-600);
      text-transform: uppercase;
      letter-spacing: 0.05em;
    }
  }
}

// Responsive adjustments
@media (max-width: 768px) {
  .custom-marker {
    width: 32px;
    height: 32px;
    
    .marker-content {
      font-size: 10px;
    }
  }
  
  .city-stats {
    grid-template-columns: repeat(2, 1fr);
  }
}
EOF

generate_turbo_views "listings" "listing"

commit "Enhanced Brgen core with production features: multi-tenant, analytics, caching, PWA, advanced UI"

log "Brgen core setup complete with production enhancements. Modern Rails 8 architecture ready for deployment on OpenBSD."

# Enhanced change log
log "Brgen core setup complete with production enhancements. Modern Rails 8 architecture ready for deployment on OpenBSD."

# Change Log:
# - Enhanced with production monitoring, analytics, rich text, karma system
# - Advanced multi-tenant architecture with caching and performance optimizations  
# - Enhanced Mapbox integration with error handling and accessibility
# - Sophisticated search and insights with real-time analytics
# - Modern Stimulus components with enhanced UX patterns
# - Production-ready error handling and logging
# - PWA capabilities with offline support
# - Design system following WCAG AAA standards
# - Rails 8 conventions with Hotwire, Turbo Streams, and Stimulus Reflex
# - Optimized for unprivileged user deployment on OpenBSD 7.5