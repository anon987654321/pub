#!/usr/bin/env zsh
# Hjerterom: Food redistribution platform with cognitive framework implementation
# Master.json v10.7.0 compliance with zero-trust security and location services

set -e
setopt extended_glob null_glob

# === COGNITIVE FRAMEWORK CONFIGURATION ===
APP_NAME="hjerterom"
BASE_DIR="/home/dev/rails"
BRGEN_IP="46.23.95.45"

# Source enhanced shared functionality
source "./__shared_enhanced.sh"

# === HJERTEROM-SPECIFIC CONFIGURATION ===
generate_application_code() {
  phase_transition "hjerterom_code_generation" "Creating food redistribution platform features"
  
  # Generate models with cognitive constraints (7 concepts max)
  bin/rails generate model Distribution location:string schedule:datetime capacity:integer lat:decimal lng:decimal
  bin/rails generate model Giveaway title:string description:text quantity:integer pickup_time:datetime location:string lat:decimal lng:decimal user:references status:string anonymous:boolean
  bin/rails generate model FoodDonation donor:references quantity:integer food_type:string expiry_date:date
  bin/rails generate model VolunteerSignup user:references distribution:references role:string
  bin/rails generate model FoodRequest requester:references quantity:integer food_type:string urgency:integer
  bin/rails generate model CommunityFeedback user:references content:text rating:integer
  bin/rails generate model SurplusAlert location:string food_type:string quantity:integer alert_time:datetime
  
  # Add Vipps and analytics support
  bin/rails generate migration AddVippsToUsers vipps_id:string citizenship_status:string claim_count:integer
  bin/rails generate migration AddAnalyticsToUsers last_activity:datetime location_data:text
  
  # Database migrations
  bin/rails db:migrate
  
  # Install additional gems for Hjerterom
  cat <<EOF >> Gemfile

# Hjerterom-specific gems
gem "omniauth-vipps", "~> 1.0"
gem "ahoy_matey", "~> 5.0"
gem "blazer", "~> 3.0"
gem "chartkick", "~> 5.0"
gem "groupdate", "~> 6.0"
gem "geocoder", "~> 1.8"
gem "image_processing", "~> 1.2"
EOF
  
  bundle install
  
  # Create cognitive-aware controllers
  cat <<EOF > app/controllers/giveaways_controller.rb
class GiveawaysController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_giveaway, only: [:show, :edit, :update, :destroy]
  before_action :check_claim_limit, only: [:create]
  
  def index
    @cognitive_load = CognitiveLoadMonitor.new
    @complexity_assessment = @cognitive_load.assess_complexity(
      "Food giveaway listings with location filtering and urgency management"
    )
    
    # Cognitive load management: limit to 7 items
    @pagy, @giveaways = pagy(filtered_giveaways.order(created_at: :desc), items: 7)
    @urgent_giveaways = Giveaway.where(status: "active")
                                .where("pickup_time < ?", 24.hours.from_now)
                                .limit(3)
    
    # Track analytics
    ahoy.track "view_giveaways", { count: @giveaways.count }
  end
  
  def show
    @cognitive_load = CognitiveLoadMonitor.new
    @complexity_assessment = @cognitive_load.assess_complexity(
      "Individual giveaway with location map and claim functionality"
    )
    
    # Track analytics
    ahoy.track "view_giveaway", { 
      id: @giveaway.id, 
      title: @giveaway.title,
      location: @giveaway.location
    }
  end
  
  def new
    @giveaway = Giveaway.new
    @cognitive_load = CognitiveLoadMonitor.new
    @complexity_assessment = @cognitive_load.assess_complexity(
      "Giveaway creation with location picker and time scheduling"
    )
  end
  
  def create
    @giveaway = Giveaway.new(giveaway_params)
    @giveaway.user = current_user
    @giveaway.status = "active"
    
    if @giveaway.save
      # Increment user claim count
      current_user.increment!(:claim_count)
      
      # Notify nearby users
      NotifyNearbyUsersJob.perform_later(@giveaway)
      
      # Track analytics
      ahoy.track "create_giveaway", {
        id: @giveaway.id,
        title: @giveaway.title,
        location: @giveaway.location,
        quantity: @giveaway.quantity
      }
      
      respond_to do |format|
        format.html { redirect_to giveaways_path, notice: "Food giveaway created successfully!" }
        format.turbo_stream
      end
    else
      render :new, status: :unprocessable_entity
    end
  end
  
  def edit
    @cognitive_load = CognitiveLoadMonitor.new
    @complexity_assessment = @cognitive_load.assess_complexity(
      "Giveaway editing with location and time updates"
    )
  end
  
  def update
    if @giveaway.update(giveaway_params)
      respond_to do |format|
        format.html { redirect_to giveaways_path, notice: "Food giveaway updated successfully!" }
        format.turbo_stream
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end
  
  def destroy
    @giveaway.destroy
    
    # Track analytics
    ahoy.track "delete_giveaway", { id: @giveaway.id }
    
    respond_to do |format|
      format.html { redirect_to giveaways_path, notice: "Food giveaway deleted successfully!" }
      format.turbo_stream
    end
  end
  
  private
  
  def set_giveaway
    @giveaway = Giveaway.find(params[:id])
    unless @giveaway.user == current_user || current_user&.admin?
      redirect_to giveaways_path, alert: "Access denied"
    end
  end
  
  def giveaway_params
    params.require(:giveaway).permit(:title, :description, :quantity, :pickup_time, :location, :lat, :lng, :anonymous)
  end
  
  def filtered_giveaways
    giveaways = Giveaway.where(status: "active")
    giveaways = giveaways.where("location ILIKE ?", "%#{params[:location]}%") if params[:location].present?
    giveaways = giveaways.where("pickup_time >= ?", Time.current) if params[:upcoming] == "true"
    giveaways
  end
  
  def check_claim_limit
    if current_user && current_user.claim_count >= 3
      redirect_to giveaways_path, alert: "You have reached your maximum number of active giveaways"
    end
  end
end
EOF
  
  # Create food redistribution model
  cat <<EOF > app/models/giveaway.rb
class Giveaway < ApplicationRecord
  belongs_to :user
  has_many :food_donations, dependent: :destroy
  has_many :volunteer_signups, dependent: :destroy
  
  validates :title, presence: true, length: { minimum: 5, maximum: 200 }
  validates :description, presence: true, length: { minimum: 10, maximum: 1000 }
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :pickup_time, presence: true
  validates :location, presence: true
  validates :status, presence: true, inclusion: { in: %w[active completed cancelled] }
  
  scope :active, -> { where(status: "active") }
  scope :urgent, -> { where("pickup_time < ?", 6.hours.from_now) }
  scope :by_location, ->(location) { where("location ILIKE ?", "%#{location}%") }
  scope :recent, -> { order(created_at: :desc) }
  
  def urgent?
    pickup_time < 6.hours.from_now
  end
  
  def time_remaining
    return 0 if pickup_time < Time.current
    ((pickup_time - Time.current) / 1.hour).round(1)
  end
  
  def display_author
    anonymous? ? "Anonymous" : user.email
  end
  
  def nearby_users(radius = 5)
    # Simple proximity calculation (in real implementation, use proper geocoding)
    User.where.not(id: user.id).limit(10)
  end
end
EOF
  
  # Create notification job
  mkdir -p app/jobs
  cat <<EOF > app/jobs/notify_nearby_users_job.rb
class NotifyNearbyUsersJob < ApplicationJob
  queue_as :default
  
  def perform(giveaway)
    # Find users within reasonable distance
    nearby_users = find_nearby_users(giveaway)
    
    nearby_users.each do |user|
      # Send notification (in real implementation, use ActionMailer or push notifications)
      NotificationService.send_food_alert(user, giveaway)
    end
    
    # Create surplus alert
    SurplusAlert.create!(
      location: giveaway.location,
      food_type: extract_food_type(giveaway.description),
      quantity: giveaway.quantity,
      alert_time: Time.current
    )
  end
  
  private
  
  def find_nearby_users(giveaway)
    # Simplified user finding (in real implementation, use proper geospatial queries)
    User.where.not(id: giveaway.user.id)
        .where("last_activity > ?", 7.days.ago)
        .limit(20)
  end
  
  def extract_food_type(description)
    food_types = %w[produce dairy meat bakery prepared frozen canned]
    food_types.find { |type| description.downcase.include?(type) } || "general"
  end
end
EOF
  
  # Create analytics dashboard controller
  cat <<EOF > app/controllers/admin/dashboard_controller.rb
class Admin::DashboardController < ApplicationController
  before_action :ensure_admin
  
  def index
    @cognitive_load = CognitiveLoadMonitor.new
    @complexity_assessment = @cognitive_load.assess_complexity(
      "Admin dashboard with food redistribution analytics and community metrics"
    )
    
    # Cognitive load management: limit to 7 key metrics
    @total_giveaways = Giveaway.count
    @active_giveaways = Giveaway.active.count
    @food_distributed = Giveaway.sum(:quantity)
    @active_users = User.where("last_activity > ?", 7.days.ago).count
    @volunteer_signups = VolunteerSignup.count
    @community_feedback_avg = CommunityFeedback.average(:rating) || 0
    @surplus_alerts = SurplusAlert.where("alert_time > ?", 24.hours.ago).count
    
    # Analytics data for charts
    @giveaway_trends = Giveaway.group_by_day(:created_at, last: 7.days).count
    @food_type_distribution = SurplusAlert.group(:food_type).count
    @location_activity = Giveaway.group(:location).count.take(10)
    
    # Track analytics
    ahoy.track "view_admin_dashboard"
  end
  
  private
  
  def ensure_admin
    redirect_to root_path, alert: "Access denied" unless current_user&.admin?
  end
end
EOF
  
  # Create enhanced home controller
  cat <<EOF > app/controllers/home_controller.rb
class HomeController < ApplicationController
  def index
    @cognitive_load = CognitiveLoadMonitor.new
    @complexity_assessment = @cognitive_load.assess_complexity(
      "Hjerterom home page with map integration and urgent food alerts"
    )
    
    # Cognitive load management: limit to 7 key elements
    @urgent_giveaways = Giveaway.urgent.limit(5)
    @recent_distributions = Distribution.order(schedule: :desc).limit(3)
    @community_stats = {
      total_giveaways: Giveaway.count,
      food_distributed: Giveaway.sum(:quantity),
      active_volunteers: VolunteerSignup.count
    }
    
    # Location-based data for map
    @map_data = {
      distributions: Distribution.limit(10),
      giveaways: Giveaway.active.limit(10)
    }
    
    # Flow state tracking
    @flow_tracker = FlowStateTracker.new
    @flow_tracker.update({
      "concentration" => 0.9,
      "challenge_skill_balance" => 0.8,
      "clear_goals" => 0.95,
      "immediate_feedback" => 0.7
    })
    
    # Track analytics
    ahoy.track "view_home", {
      urgent_giveaways: @urgent_giveaways.count,
      user_location: request.location&.city
    }
  end
end
EOF
  
  # Create location-based initializer
  cat <<EOF > config/initializers/geocoder.rb
Geocoder.configure(
  # Use a reliable geocoding service
  lookup: :nominatim,
  timeout: 3,
  units: :km,
  
  # Cache geocoding results
  cache: Rails.cache,
  cache_options: { expires_in: 1.day }
)
EOF
  
  # Create analytics initializer
  cat <<EOF > config/initializers/ahoy.rb
class Ahoy::Store < Ahoy::DatabaseStore
  def track_visit(data)
    # Add cognitive load tracking to visits
    data[:cognitive_load] = calculate_page_complexity(data[:landing_page])
    super(data)
  end
  
  private
  
  def calculate_page_complexity(page)
    # Simple complexity calculation based on page type
    case page
    when /admin/
      7.0
    when /giveaways.*new/, /giveaways.*edit/
      6.0
    when /giveaways/
      4.0
    else
      3.0
    end
  end
end

Ahoy.track_visits_immediately = true
Ahoy.geocode = :ip_to_country_code
EOF
  
  # Create seed data
  cat <<EOF > db/seeds.rb
# Create sample distributions
distributions = [
  {
    location: "Åsane Community Center, Bergen",
    schedule: 1.day.from_now,
    capacity: 50,
    lat: 60.4651,
    lng: 5.2897
  },
  {
    location: "Bergen Food Bank",
    schedule: 2.days.from_now,
    capacity: 100,
    lat: 60.3913,
    lng: 5.3221
  },
  {
    location: "Flesland Distribution Point",
    schedule: 3.days.from_now,
    capacity: 75,
    lat: 60.2934,
    lng: 5.2181
  }
]

distributions.each do |dist_attrs|
  Distribution.find_or_create_by(location: dist_attrs[:location]) do |distribution|
    distribution.schedule = dist_attrs[:schedule]
    distribution.capacity = dist_attrs[:capacity]
    distribution.lat = dist_attrs[:lat]
    distribution.lng = dist_attrs[:lng]
  end
end

# Create sample food types for categorization
food_types = %w[produce dairy meat bakery prepared frozen canned]

food_types.each do |type|
  SurplusAlert.create!(
    location: "Bergen City Center",
    food_type: type,
    quantity: rand(5..50),
    alert_time: rand(1..48).hours.ago
  )
end

puts "✅ Hjerterom seed data created successfully!"
puts "🥕 #{Distribution.count} distributions created"
puts "🍎 #{SurplusAlert.count} surplus alerts created"
EOF
  
  # Run seeds
  bin/rails db:seed
  
  log "Hjerterom application code generation completed" "INFO"
}

# Override main to use enhanced installation
main() {
  log "Starting Hjerterom installation with cognitive framework" "INFO"
  
  # Use enhanced shared installation
  source "./__shared_enhanced.sh"
  
  # Run the main installation process
  if command -v initialize_application > /dev/null 2>&1; then
    # Run enhanced installation
    initialize_application
    setup_rails_application
    setup_database
    setup_cognitive_framework
    setup_authentication
    setup_security
    generate_application_code  # This will use our Hjerterom-specific implementation
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

install_gem "omniauth-vipps"
install_gem "ahoy_matey"
install_gem "blazer"
install_gem "chartkick"

bin/rails generate model Distribution location:string schedule:datetime capacity:integer lat:decimal lng:decimal
bin/rails generate model Giveaway title:string description:text quantity:integer pickup_time:datetime location:string lat:decimal lng:decimal user:references status:string anonymous:boolean
bin/rails generate migration AddVippsToUsers vipps_id:string citizenship_status:string claim_count:integer

cat <<EOF > config/initializers/ahoy.rb
class Ahoy::Store < Ahoy::DatabaseStore
end

Ahoy.track_visits_immediately = true
EOF

cat <<EOF > config/initializers/blazer.rb
Blazer.data_sources["main"] = {
  url: ENV["DATABASE_URL"],
  smart_variables: {
    user_id: "SELECT id, email FROM users ORDER BY email"
  }
}
EOF

cat <<EOF > app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  before_action :authenticate_user!, except: [:index, :show], unless: :guest_user_allowed?

  def after_sign_in_path_for(resource)
    root_path
  end

  private

  def guest_user_allowed?
    controller_name == "home" || 
    (controller_name == "posts" && action_name.in?(["index", "show", "create"])) || 
    (controller_name == "distributions" && action_name.in?(["index", "show"])) || 
    (controller_name == "giveaways" && action_name.in?(["index", "show"]))
  end
end
EOF

cat <<EOF > app/controllers/home_controller.rb
class HomeController < ApplicationController
  before_action :initialize_post, only: [:index]

  def index
    @pagy, @posts = pagy(Post.all.order(created_at: :desc), items: 10) unless @stimulus_reflex
    @distributions = Distribution.all.order(schedule: :desc).limit(5)
    @giveaways = Giveaway.where(status: "active").order(created_at: :desc).limit(5)
    ahoy.track "View home", { posts: @posts.count }
  end

  private

  def initialize_post
    @post = Post.new
  end
end
EOF

cat <<EOF > app/controllers/distributions_controller.rb
class DistributionsController < ApplicationController
  before_action :set_distribution, only: [:show]

  def index
    @pagy, @distributions = pagy(Distribution.all.order(schedule: :desc)) unless @stimulus_reflex
    ahoy.track "View distributions", { count: @distributions.count }
  end

  def show
    ahoy.track "View distribution", { id: @distribution.id }
  end

  private

  def set_distribution
    @distribution = Distribution.find(params[:id])
  end
end
EOF

cat <<EOF > app/controllers/giveaways_controller.rb
class GiveawaysController < ApplicationController
  before_action :set_giveaway, only: [:show, :edit, :update, :destroy]
  before_action :initialize_giveaway, only: [:index, :new]
  before_action :check_claim_limit, only: [:create]

  def index
    @pagy, @giveaways = pagy(Giveaway.where(status: "active").order(created_at: :desc)) unless @stimulus_reflex
    ahoy.track "View giveaways", { count: @giveaways.count }
  end

  def show
    ahoy.track "View giveaway", { id: @giveaway.id }
  end

  def new
  end

  def create
    @giveaway = Giveaway.new(giveaway_params)
    @giveaway.user = current_user
    @giveaway.status = "active"
    if @giveaway.save
      current_user.increment!(:claim_count)
      ahoy.track "Create giveaway", { id: @giveaway.id, title: @giveaway.title }
      respond_to do |format|
        format.html { redirect_to giveaways_path, notice: t("hjerterom.giveaway_created") }
        format.turbo_stream
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @giveaway.update(giveaway_params)
      ahoy.track "Update giveaway", { id: @giveaway.id, title: @giveaway.title }
      respond_to do |format|
        format.html { redirect_to giveaways_path, notice: t("hjerterom.giveaway_updated") }
        format.turbo_stream
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @giveaway.destroy
    ahoy.track "Delete giveaway", { id: @giveaway.id }
    respond_to do |format|
      format.html { redirect_to giveaways_path, notice: t("hjerterom.giveaway_deleted") }
      format.turbo_stream
    end
  end

  private

  def set_giveaway
    @giveaway = Giveaway.find(params[:id])
    redirect_to giveaways_path, alert: t("hjerterom.not_authorized") unless @giveaway.user == current_user || current_user&.admin?
  end

  def initialize_giveaway
    @giveaway = Giveaway.new
  end

  def check_claim_limit
    if current_user && current_user.claim_count >= 1
      redirect_to giveaways_path, alert: t("hjerterom.claim_limit_exceeded")
    end
  end

  def giveaway_params
    params.require(:giveaway).permit(:title, :description, :quantity, :pickup_time, :location, :lat, :lng, :anonymous)
  end
end
EOF

cat <<EOF > app/controllers/admin/dashboard_controller.rb
class Admin::DashboardController < ApplicationController
  before_action :ensure_admin

  def index
    @distributions = Distribution.all.order(schedule: :desc).limit(10)
    @giveaways = Giveaway.all.order(created_at: :desc).limit(10)
    @users = User.all.order(claim_count: :desc).limit(10)
    @total_distributed = Distribution.sum(:capacity)
    @total_giveaways = Giveaway.count
    @active_users = User.where("claim_count > 0").count
    @visit_stats = Ahoy::Event.group_by_day(:name).count
    @giveaway_trends = Giveaway.group_by_day(:created_at).count
    ahoy.track "View admin dashboard"
  end

  private

  def ensure_admin
    redirect_to root_path, alert: t("hjerterom.not_authorized") unless current_user&.admin?
  end
end
EOF

cat <<EOF > app/controllers/posts_controller.rb
class PostsController < ApplicationController
  before_action :set_post, only: [:show, :edit, :update, :destroy]
  before_action :initialize_post, only: [:index, :new]

  def index
    @pagy, @posts = pagy(Post.all.order(created_at: :desc)) unless @stimulus_reflex
    ahoy.track "View posts", { count: @posts.count }
  end

  def show
    ahoy.track "View post", { id: @post.id }
  end

  def new
  end

  def create
    @post = Post.new(post_params)
    @post.user = current_user || User.guest
    if @post.save
      ahoy.track "Create post", { id: @post.id, title: @post.title }
      respond_to do |format|
        format.html { redirect_to root_path, notice: t("hjerterom.post_created") }
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
      ahoy.track "Update post", { id: @post.id, title: @post.title }
      respond_to do |format|
        format.html { redirect_to root_path, notice: t("hjerterom.post_updated") }
        format.turbo_stream
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @post.destroy
    ahoy.track "Delete post", { id: @post.id }
    respond_to do |format|
      format.html { redirect_to root_path, notice: t("hjerterom.post_deleted") }
      format.turbo_stream
    end
  end

  private

  def set_post
    @post = Post.find(params[:id])
    redirect_to root_path, alert: t("hjerterom.not_authorized") unless @post.user == current_user || current_user&.admin?
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

cat <<EOF > app/reflexes/vote_reflex.rb
class VoteReflex < ApplicationReflex
  def upvote
    votable = element.dataset["votable_type"].constantize.find(element.dataset["votable_id"])
    vote = Vote.find_or_initialize_by(votable: votable, user: current_user || User.guest)
    vote.update(value: 1)
    cable_ready
      .replace(selector: "#vote-#{votable.id}", html: render(partial: "shared/vote", locals: { votable: votable }))
      .broadcast
  end

  def downvote
    votable = element.dataset["votable_type"].constantize.find(element.dataset["votable_id"])
    vote = Vote.find_or_initialize_by(votable: votable, user: current_user || User.guest)
    vote.update(value: -1)
    cable_ready
      .replace(selector: "#vote-#{votable.id}", html: render(partial: "shared/vote", locals: { votable: votable }))
      .broadcast
  end
end
EOF

cat <<EOF > app/reflexes/chat_reflex.rb
class ChatReflex < ApplicationReflex
  def send_message
    message = Message.create(
      content: element.dataset["content"],
      sender: current_user || User.guest,
      receiver_id: element.dataset["receiver_id"],
      anonymous: element.dataset["anonymous"] == "true"
    )
    ActionCable.server.broadcast("chat_channel", {
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
    stream_from "chat_channel"
  end
end
EOF

cat <<EOF > app/javascript/controllers/mapbox_controller.js
import { Controller } from "@hotwired/stimulus"
import mapboxgl from "mapbox-gl"
import MapboxGeocoder from "mapbox-gl-geocoder"

export default class extends Controller {
  static values = { apiKey: String, distributions: Array, giveaways: Array }

  connect() {
    mapboxgl.accessToken = this.apiKeyValue
    this.map = new mapboxgl.Map({
      container: this.element,
      style: "mapbox://styles/mapbox/streets-v11",
      center: [5.3467, 60.3971], // Åsane, Bergen
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
    this.distributionsValue.forEach(dist => {
      new mapboxgl.Marker({ color: "#1a73e8" })
        .setLngLat([dist.lng, dist.lat])
        .setPopup(new mapboxgl.Popup().setHTML(\`<h3>Distribution</h3><p>\${dist.schedule}</p>\`))
        .addTo(this.map)
    })

    this.giveawaysValue.forEach(give => {
      new mapboxgl.Marker({ color: "#e91e63" })
        .setLngLat([give.lng, give.lat])
        .setPopup(new mapboxgl.Popup().setHTML(\`<h3>\${give.title}</h3><p>\${give.description}</p>\`))
        .addTo(this.map)
    })
  }
}
EOF

cat <<EOF > app/javascript/controllers/chat_controller.js
import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

export default class extends Controller {
  static targets = ["input", "messages"]

  connect() {
    this.consumer = createConsumer()
    this.channel = this.consumer.subscriptions.create("ChatChannel", {
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

cat <<EOF > app/javascript/controllers/countdown_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["days", "hours", "minutes"]
  static values = { endDate: String }

  connect() {
    this.updateCountdown()
    this.interval = setInterval(() => this.updateCountdown(), 60000)
  }

  updateCountdown() {
    const end = new Date(this.endDateValue)
    const now = new Date()
    const diff = end - now

    if (diff <= 0) {
      this.daysTarget.textContent = "0"
      this.hoursTarget.textContent = "0"
      this.minutesTarget.textContent = "0"
      clearInterval(this.interval)
      return
    }

    const days = Math.floor(diff / (1000 * 60 * 60 * 24))
    const hours = Math.floor((diff % (1000 * 60 * 60 * 24)) / (1000 * 60 * 60))
    const minutes = Math.floor((diff % (1000 * 60 * 60)) / (1000 * 60))

    this.daysTarget.textContent = days
    this.hoursTarget.textContent = hours
    this.minutesTarget.textContent = minutes
  }

  disconnect() {
    clearInterval(this.interval)
  }
}
EOF

mkdir -p app/views/hjerterom_logo

cat <<EOF > app/views/hjerterom_logo/_logo.html.erb
<%= tag.svg xmlns: "http://www.w3.org/2000/svg", viewBox: "0 0 100 50", role: "img", class: "logo", "aria-label": t("hjerterom.logo_alt") do %>
  <%= tag.title t("hjerterom.logo_title", default: "Hjerterom Logo") %>
  <%= tag.path d: "M50 15 C70 5, 90 25, 50 45 C10 25, 30 5, 50 15", fill: "#e91e63", stroke: "#1a73e8", "stroke-width": "2" %>
<% end %>
EOF

cat <<EOF > app/views/home/index.html.erb
<% content_for :title, t("hjerterom.home_title") %>
<% content_for :description, t("hjerterom.home_description") %>
<% content_for :keywords, t("hjerterom.home_keywords", default: "hjerterom, food redistribution, åsane, surplus food") %>
<% content_for :schema do %>
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "WebPage",
    "name": "<%= t('hjerterom.home_title') %>",
    "description": "<%= t('hjerterom.home_description') %>",
    "url": "<%= request.original_url %>",
    "publisher": {
      "@type": "Organization",
      "name": "Hjerterom",
      "logo": {
        "@type": "ImageObject",
        "url": "<%= image_url('hjerterom_logo.svg') %>"
      }
    }
  }
  </script>
<% end %>
<%= tag.header role: "banner" do %>
  <%= render partial: "hjerterom_logo/logo" %>
<% end %>
<%= tag.main role: "main" do %>
  <%= tag.section aria-labelledby: "urgent-heading" class: "urgent" do %>
    <%= tag.h1 t("hjerterom.urgent_title"), id: "urgent-heading" %>
    <%= tag.div data: { turbo_frame: "notices" } do %>
      <%= render "shared/notices" %>
    <% end %>
    <%= tag.p t("hjerterom.urgent_message") %>
    <%= tag.div id: "countdown" data: { controller: "countdown", "countdown-end-date-value": "2025-06-30T23:59:59Z" } do %>
      <%= tag.span data: { "countdown-target": "days" } %>
      <%= tag.span t("hjerterom.days") %>
      <%= tag.span data: { "countdown-target": "hours" } %>
      <%= tag.span t("hjerterom.hours") %>
      <%= tag.span data: { "countdown-target": "minutes" } %>
      <%= tag.span t("hjerterom.minutes") %>
    <% end %>
    <%= link_to t("hjerterom.offer_space"), "#", class: "button", "aria-label": t("hjerterom.offer_space") %>
    <%= link_to t("hjerterom.donate"), "#", class: "button", "aria-label": t("hjerterom.donate") %>
  <% end %>
  <%= tag.section aria-labelledby: "post-heading" do %>
    <%= tag.h2 t("hjerterom.post_title"), id: "post-heading" %>
    <%= form_with model: @post, local: true, data: { controller: "character-counter form-validation", turbo: true } do |form| %>
      <%= tag.div data: { turbo_frame: "notices" } do %>
        <%= render "shared/notices" %>
      <% end %>
      <%= tag.fieldset do %>
        <%= form.label :body, t("hjerterom.post_body"), "aria-required": true %>
        <%= form.text_area :body, placeholder: t("hjerterom.whats_on_your_heart"), required: true, data: { "character-counter-target": "input", "textarea-autogrow-target": "input", "form-validation-target": "input", action: "input->character-counter#count input->textarea-autogrow#resize input->form-validation#validate" }, title: t("hjerterom.post_body_help") %>
        <%= tag.span data: { "character-counter-target": "count" } %>
        <%= tag.span class: "error-message" data: { "form-validation-target": "error", for: "post_body" } %>
      <% end %>
      <%= tag.fieldset do %>
        <%= form.check_box :anonymous %>
        <%= form.label :anonymous, t("hjerterom.post_anonymously") %>
      <% end %>
      <%= form.submit t("hjerterom.post_submit"), data: { turbo_submits_with: t("hjerterom.post_submitting") } %>
    <% end %>
  <% end %>
  <%= tag.section aria-labelledby: "map-heading" do %>
    <%= tag.h2 t("hjerterom.map_title"), id: "map-heading" %>
    <%= tag.div id: "map" data: { controller: "mapbox", "mapbox-api-key-value": ENV["MAPBOX_API_KEY"], "mapbox-distributions-value": @distributions.to_json, "mapbox-giveaways-value": @giveaways.to_json } %>
  <% end %>
  <%= tag.section aria-labelledby: "search-heading" do %>
    <%= tag.h2 t("hjerterom.search_title"), id: "search-heading" %>
    <%= tag.div data: { controller: "search", model: "Post", field: "title" } do %>
      <%= tag.input type: "text", placeholder: t("hjerterom.search_placeholder"), data: { "search-target": "input", action: "input->search#search" }, "aria-label": t("hjerterom.search_posts") %>
      <%= tag.div id: "search-results", data: { "search-target": "results" } %>
      <%= tag.div id: "reset-link" %>
    <% end %>
  <% end %>
  <%= tag.section aria-labelledby: "posts-heading" do %>
    <%= tag.h2 t("hjerterom.posts_title"), id: "posts-heading" %>
    <%= turbo_frame_tag "posts" data: { controller: "infinite-scroll" } do %>
      <% @posts.each do |post| %>
        <%= render partial: "posts/post", locals: { post: post } %>
      <% end %>
      <%= tag.div id: "sentinel", class: "hidden", data: { reflex: "PostsInfiniteScroll#load_more", next_page: @pagy.next || 2 } %>
    <% end %>
    <%= tag.button t("hjerterom.load_more"), id: "load-more", data: { reflex: "click->PostsInfiniteScroll#load_more", "next-page": @pagy.next || 2, "reflex-root": "#load-more" }, class: @pagy&.next ? "" : "hidden", "aria-label": t("hjerterom.load_more") %>
  <% end %>
  <%= tag.section aria-labelledby: "distributions-heading" do %>
    <%= tag.h2 t("hjerterom.distributions_title"), id: "distributions-heading" %>
    <%= turbo_frame_tag "distributions" do %>
      <% @distributions.each do |distribution| %>
        <%= render partial: "distributions/distribution", locals: { distribution: distribution } %>
      <% end %>
    <% end %>
  <% end %>
  <%= tag.section aria-labelledby: "giveaways-heading" do %>
    <%= tag.h2 t("hjerterom.giveaways_title"), id: "giveaways-heading" %>
    <%= link_to t("hjerterom.new_giveaway"), new_giveaway_path, class: "button", "aria-label": t("hjerterom.new_giveaway") if current_user %>
    <%= turbo_frame_tag "giveaways" do %>
      <% @giveaways.each do |giveaway| %>
        <%= render partial: "giveaways/giveaway", locals: { giveaway: giveaway } %>
      <% end %>
    <% end %>
  <% end %>
  <%= tag.section id: "chat" aria-labelledby: "chat-heading" do %>
    <%= tag.h2 t("hjerterom.chat_title"), id: "chat-heading" %>
    <%= tag.div id: "messages" data: { "chat-target": "messages" }, "aria-live": "polite" %>
    <%= form_with url: "#", method: :post, local: true, data: { controller: "chat", "chat-receiver-id": "global", "chat-anonymous": "true" } do |form| %>
      <%= tag.fieldset do %>
        <%= form.label :content, t("hjerterom.chat_placeholder"), class: "sr-only" %>
        <%= form.text_field :content, placeholder: t("hjerterom.chat_placeholder"), data: { "chat-target": "input", action: "submit->chat#send" }, "aria-label": t("hjerterom.chat_placeholder") %>
      <% end %>
    <% end %>
  <% end %>
<% end %>
<%= tag.footer role: "contentinfo" do %>
  <%= tag.nav class: "footer-links" aria-label: t("shared.footer_nav") do %>
    <%= link_to "", "https://facebook.com", class: "footer-link fb", "aria-label": "Facebook" %>
    <%= link_to "", "https://twitter.com", class: "footer-link tw", "aria-label": "Twitter" %>
    <%= link_to "", "https://instagram.com", class: "footer-link ig", "aria-label": "Instagram" %>
    <%= link_to t("shared.about"), "#", class: "footer-link text" %>
    <%= link_to t("shared.contact"), "#", class: "footer-link text" %>
    <%= link_to t("shared.donate"), "#", class: "footer-link text" %>
    <%= link_to t("shared.volunteer"), "#", class: "footer-link text" %>
  <% end %>
<% end %>
EOF

cat <<EOF > app/views/distributions/index.html.erb
<% content_for :title, t("hjerterom.distributions_title") %>
<% content_for :description, t("hjerterom.distributions_description") %>
<% content_for :keywords, t("hjerterom.distributions_keywords", default: "food distribution, surplus food, hjerterom, åsane") %>
<% content_for :schema do %>
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "WebPage",
    "name": "<%= t('hjerterom.distributions_title') %>",
    "description": "<%= t('hjerterom.distributions_description') %>",
    "url": "<%= request.original_url %>",
    "hasPart": [
      <% @distributions.each do |dist| %>
      {
        "@type": "Event",
        "name": "Food Distribution",
        "startDate": "<%= dist.schedule.iso8601 %>",
        "location": {
          "@type": "Place",
          "name": "<%= dist.location %>",
          "geo": {
            "@type": "GeoCoordinates",
            "latitude": "<%= dist.lat %>",
            "longitude": "<%= dist.lng %>"
          }
        }
      }<%= "," unless dist == @distributions.last %>
      <% end %>
    ]
  }
  </script>
<% end %>
<%= tag.header role: "banner" do %>
  <%= render partial: "hjerterom_logo/logo" %>
<% end %>
<%= tag.main role: "main" do %>
  <%= tag.section aria-labelledby: "distributions-heading" do %>
    <%= tag.h1 t("hjerterom.distributions_title"), id: "distributions-heading" %>
    <%= tag.div data: { turbo_frame: "notices" } do %>
      <%= render "shared/notices" %>
    <% end %>
    <%= turbo_frame_tag "distributions" do %>
      <% @distributions.each do |distribution| %>
        <%= render partial: "distributions/distribution", locals: { distribution: distribution } %>
      <% end %>
    <% end %>
  <% end %>
<% end %>
<%= tag.footer role: "contentinfo" do %>
  <%= tag.nav class: "footer-links" aria-label: t("shared.footer_nav") do %>
    <%= link_to "", "https://facebook.com", class: "footer-link fb", "aria-label": "Facebook" %>
    <%= link_to "", "https://twitter.com", class: "footer-link tw", "aria-label": "Twitter" %>
    <%= link_to "", "https://instagram.com", class: "footer-link ig", "aria-label": "Instagram" %>
    <%= link_to t("shared.about"), "#", class: "footer-link text" %>
    <%= link_to t("shared.contact"), "#", class: "footer-link text" %>
    <%= link_to t("shared.donate"), "#", class: "footer-link text" %>
    <%= link_to t("shared.volunteer"), "#", class: "footer-link text" %>
  <% end %>
<% end %>
EOF

cat <<EOF > app/views/distributions/_distribution.html.erb
<%= turbo_frame_tag dom_id(distribution) do %>
  <%= tag.article class: "post-card", id: dom_id(distribution), role: "article" do %>
    <%= tag.h2 t("hjerterom.distribution_title", location: distribution.location) %>
    <%= tag.p t("hjerterom.schedule", schedule: distribution.schedule.strftime("%Y-%m-%d %H:%M")) %>
    <%= tag.p t("hjerterom.capacity", capacity: distribution.capacity) %>
    <%= tag.p class: "post-actions" do %>
      <%= link_to t("hjerterom.view_distribution"), distribution_path(distribution), "aria-label": t("hjerterom.view_distribution") %>
    <% end %>
  <% end %>
<% end %>
EOF

cat <<EOF > app/views/distributions/show.html.erb
<% content_for :title, t("hjerterom.distribution_title", location: @distribution.location) %>
<% content_for :description, t("hjerterom.distribution_description", location: @distribution.location) %>
<% content_for :keywords, t("hjerterom.distribution_keywords", default: "food distribution, #{@distribution.location}, hjerterom") %>
<% content_for :schema do %>
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "Event",
    "name": "Food Distribution at <%= @distribution.location %>",
    "description": "<%= t('hjerterom.distribution_description', location: @distribution.location) %>",
    "startDate": "<%= @distribution.schedule.iso8601 %>",
    "location": {
      "@type": "Place",
      "name": "<%= @distribution.location %>",
      "geo": {
        "@type": "GeoCoordinates",
        "latitude": "<%= @distribution.lat %>",
        "longitude": "<%= @distribution.lng %>"
      }
    }
  }
  </script>
<% end %>
<%= tag.header role: "banner" do %>
  <%= render partial: "hjerterom_logo/logo" %>
<% end %>
<%= tag.main role: "main" do %>
  <%= tag.section aria-labelledby: "distribution-heading" class: "post-card" do %>
    <%= tag.div data: { turbo_frame: "notices" } do %>
      <%= render "shared/notices" %>
    <% end %>
    <%= tag.h1 t("hjerterom.distribution_title", location: @distribution.location), id: "distribution-heading" %>
    <%= tag.p t("hjerterom.schedule", schedule: @distribution.schedule.strftime("%Y-%m-%d %H:%M")) %>
    <%= tag.p t("hjerterom.capacity", capacity: @distribution.capacity) %>
    <%= link_to t("hjerterom.back_to_distributions"), distributions_path, class: "button", "aria-label": t("hjerterom.back_to_distributions") %>
  <% end %>
<% end %>
<%= tag.footer role: "contentinfo" do %>
  <%= tag.nav class: "footer-links" aria-label: t("shared.footer_nav") do %>
    <%= link_to "", "https://facebook.com", class: "footer-link fb", "aria-label": "Facebook" %>
    <%= link_to "", "https://twitter.com", class: "footer-link tw", "aria-label": "Twitter" %>
    <%= link_to "", "https://instagram.com", class: "footer-link ig", "aria-label": "Instagram" %>
    <%= link_to t("shared.about"), "#", class: "footer-link text" %>
    <%= link_to t("shared.contact"), "#", class: "footer-link text" %>
    <%= link_to t("shared.donate"), "#", class: "footer-link text" %>
    <%= link_to t("shared.volunteer"), "#", class: "footer-link text" %>
  <% end %>
<% end %>
EOF

cat <<EOF > app/views/giveaways/index.html.erb
<% content_for :title, t("hjerterom.giveaways_title") %>
<% content_for :description, t("hjerterom.giveaways_description") %>
<% content_for :keywords, t("hjerterom.giveaways_keywords", default: "food giveaways, donate food, hjerterom, åsane") %>
<% content_for :schema do %>
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "WebPage",
    "name": "<%= t('hjerterom.giveaways_title') %>",
    "description": "<%= t('hjerterom.giveaways_description') %>",
    "url": "<%= request.original_url %>",
    "hasPart": [
      <% @giveaways.each do |giveaway| %>
      {
        "@type": "Product",
        "name": "<%= giveaway.title %>",
        "description": "<%= giveaway.description&.truncate(160) %>",
        "geo": {
          "@type": "GeoCoordinates",
          "latitude": "<%= giveaway.lat %>",
          "longitude": "<%= giveaway.lng %>"
        }
      }<%= "," unless giveaway == @giveaways.last %>
      <% end %>
    ]
  }
  </script>
<% end %>
<%= tag.header role: "banner" do %>
  <%= render partial: "hjerterom_logo/logo" %>
<% end %>
<%= tag.main role: "main" do %>
  <%= tag.section aria-labelledby: "giveaways-heading" do %>
    <%= tag.h1 t("hjerterom.giveaways_title"), id: "giveaways-heading" %>
    <%= tag.div data: { turbo_frame: "notices" } do %>
      <%= render "shared/notices" %>
    <% end %>
    <%= link_to t("hjerterom.new_giveaway"), new_giveaway_path, class: "button", "aria-label": t("hjerterom.new_giveaway") if current_user %>
    <%= turbo_frame_tag "giveaways" do %>
      <% @giveaways.each do |giveaway| %>
        <%= render partial: "giveaways/giveaway", locals: { giveaway: giveaway } %>
      <% end %>
    <% end %>
  <% end %>
  <%= tag.section aria-labelledby: "search-heading" do %>
    <%= tag.h2 t("hjerterom.search_title"), id: "search-heading" %>
    <%= tag.div data: { controller: "search", model: "Giveaway", field: "title" } do %>
      <%= tag.input type: "text", placeholder: t("hjerterom.search_placeholder"), data: { "search-target": "input", action: "input->search#search" }, "aria-label": t("hjerterom.search_giveaways") %>
      <%= tag.div id: "search-results", data: { "search-target": "results" } %>
      <%= tag.div id: "reset-link" %>
    <% end %>
  <% end %>
<% end %>
<%= tag.footer role: "contentinfo" do %>
  <%= tag.nav class: "footer-links" aria-label: t("shared.footer_nav") do %>
    <%= link_to "", "https://facebook.com", class: "footer-link fb", "aria-label": "Facebook" %>
    <%= link_to "", "https://twitter.com", class: "footer-link tw", "aria-label": "Twitter" %>
    <%= link_to "", "https://instagram.com", class: "footer-link ig", "aria-label": "Instagram" %>
    <%= link_to t("shared.about"), "#", class: "footer-link text" %>
    <%= link_to t("shared.contact"), "#", class: "footer-link text" %>
    <%= link_to t("shared.donate"), "#", class: "footer-link text" %>
    <%= link_to t("shared.volunteer"), "#", class: "footer-link text" %>
  <% end %>
<% end %>
EOF

cat <<EOF > app/views/giveaways/_giveaway.html.erb
<%= turbo_frame_tag dom_id(giveaway) do %>
  <%= tag.article class: "post-card", id: dom_id(giveaway), role: "article" do %>
    <%= tag.div class: "post-header" do %>
      <%= tag.span t("hjerterom.posted_by", user: giveaway.anonymous? ? "Anonymous" : giveaway.user.email) %>
      <%= tag.span giveaway.created_at.strftime("%Y-%m-%d %H:%M") %>
    <% end %>
    <%= tag.h2 giveaway.title %>
    <%= tag.p giveaway.description %>
    <%= tag.p t("hjerterom.quantity", quantity: giveaway.quantity) %>
    <%= tag.p t("hjerterom.pickup_time", pickup_time: giveaway.pickup_time.strftime("%Y-%m-%d %H:%M")) %>
    <%= tag.p t("hjerterom.location", location: giveaway.location) %>
    <%= render partial: "shared/vote", locals: { votable: giveaway } %>
    <%= tag.p class: "post-actions" do %>
      <%= link_to t("hjerterom.view_giveaway"), giveaway_path(giveaway), "aria-label": t("hjerterom.view_giveaway") %>
      <%= link_to t("hjerterom.edit_giveaway"), edit_giveaway_path(giveaway), "aria-label": t("hjerterom.edit_giveaway") if giveaway.user == current_user || current_user&.admin? %>
      <%= button_to t("hjerterom.delete_giveaway"), giveaway_path(giveaway), method: :delete, data: { turbo_confirm: t("hjerterom.confirm_delete") }, form: { data: { turbo_frame: "_top" } }, "aria-label