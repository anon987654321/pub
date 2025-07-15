#!/usr/bin/env zsh
# Brgen Dating: Location-based dating platform with cognitive framework implementation
# Master.json v10.7.0 compliance with zero-trust security and privacy-focused matching

set -e
setopt extended_glob null_glob

# === COGNITIVE FRAMEWORK CONFIGURATION ===
APP_NAME="brgen_dating"
BASE_DIR="/home/dev/rails"
BRGEN_IP="46.23.95.45"

# Source enhanced shared functionality
source "../../__shared_enhanced.sh"

# === DATING-SPECIFIC CONFIGURATION ===
generate_application_code() {
  phase_transition "dating_code_generation" "Creating privacy-focused dating platform features"
  
  # Generate models with cognitive constraints (7 concepts max)
  bin/rails generate model Profile user:references bio:text location:string lat:decimal lng:decimal gender:string age:integer
  bin/rails generate model Match initiator:references receiver:references status:string matched_at:datetime
  bin/rails generate model PrivacySettings user:references location_visible:boolean show_age:boolean show_last_seen:boolean
  bin/rails generate model UserPreference user:references min_age:integer max_age:integer max_distance:integer preferred_gender:string
  bin/rails generate model ProfilePhoto profile:references image:attachment primary:boolean approved:boolean
  bin/rails generate model UserInteraction actor:references target:references interaction_type:string
  bin/rails generate model SafetyReport reporter:references reported_user:references reason:string description:text
  
  # Database migrations
  bin/rails db:migrate
  
  # Install additional gems for Dating
  cat <<EOF >> Gemfile

# Dating-specific gems
gem "geocoder", "~> 1.8"
gem "geokit-rails", "~> 2.5"
gem "image_processing", "~> 1.2"
gem "mini_magick", "~> 4.11"
gem "chronic", "~> 0.10"
gem "content_moderation", "~> 1.0"
gem "encryption", "~> 1.3"
EOF
  
  bundle install
  
  # Create cognitive-aware controllers
  cat <<EOF > app/controllers/profiles_controller.rb
class ProfilesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_profile, only: [:show, :edit, :update, :destroy]
  before_action :ensure_own_profile, only: [:edit, :update, :destroy]
  
  def index
    @cognitive_load = CognitiveLoadMonitor.new
    @complexity_assessment = @cognitive_load.assess_complexity(
      "Profile discovery with location filtering and preference matching"
    )
    
    # Cognitive load management: limit to 7 profiles
    @profiles = filtered_profiles.limit(7)
    @user_preferences = current_user.user_preferences.first || UserPreference.new
    @nearby_count = nearby_profiles_count
  end
  
  def show
    @cognitive_load = CognitiveLoadMonitor.new
    @complexity_assessment = @cognitive_load.assess_complexity(
      "Profile viewing with match potential and safety controls"
    )
    
    # Privacy-aware profile display
    @can_view_location = can_view_location?(@profile)
    @can_view_age = can_view_age?(@profile)
    @can_view_last_seen = can_view_last_seen?(@profile)
    
    # Safety features
    @is_blocked = user_blocked?(@profile.user)
    @can_report = can_report_user?(@profile.user)
    
    # Match compatibility
    @compatibility_score = calculate_compatibility(@profile)
  end
  
  def new
    @profile = Profile.new
    @cognitive_load = CognitiveLoadMonitor.new
    @complexity_assessment = @cognitive_load.assess_complexity(
      "Profile creation with photo upload and privacy settings"
    )
    
    @privacy_settings = PrivacySettings.new
    @user_preferences = UserPreference.new
  end
  
  def create
    @profile = Profile.new(profile_params)
    @profile.user = current_user
    
    if @profile.save
      # Create default privacy settings
      PrivacySettings.create!(
        user: current_user,
        location_visible: true,
        show_age: true,
        show_last_seen: false
      )
      
      # Create default user preferences
      UserPreference.create!(
        user: current_user,
        min_age: 18,
        max_age: 99,
        max_distance: 50,
        preferred_gender: "any"
      )
      
      respond_to do |format|
        format.html { redirect_to profiles_path, notice: "Profile created successfully!" }
        format.turbo_stream
      end
    else
      @privacy_settings = PrivacySettings.new
      @user_preferences = UserPreference.new
      render :new, status: :unprocessable_entity
    end
  end
  
  def edit
    @cognitive_load = CognitiveLoadMonitor.new
    @complexity_assessment = @cognitive_load.assess_complexity(
      "Profile editing with privacy and preference management"
    )
    
    @privacy_settings = current_user.privacy_settings || PrivacySettings.new
    @user_preferences = current_user.user_preferences.first || UserPreference.new
  end
  
  def update
    if @profile.update(profile_params)
      # Update privacy settings if provided
      if privacy_params.present?
        privacy_settings = current_user.privacy_settings || current_user.build_privacy_settings
        privacy_settings.update(privacy_params)
      end
      
      # Update user preferences if provided
      if preference_params.present?
        user_preferences = current_user.user_preferences.first || current_user.user_preferences.build
        user_preferences.update(preference_params)
      end
      
      respond_to do |format|
        format.html { redirect_to @profile, notice: "Profile updated successfully!" }
        format.turbo_stream
      end
    else
      @privacy_settings = current_user.privacy_settings || PrivacySettings.new
      @user_preferences = current_user.user_preferences.first || UserPreference.new
      render :edit, status: :unprocessable_entity
    end
  end
  
  def destroy
    @profile.destroy
    respond_to do |format|
      format.html { redirect_to profiles_path, notice: "Profile deleted successfully!" }
      format.turbo_stream
    end
  end
  
  def like
    target_profile = Profile.find(params[:id])
    
    # Record interaction
    UserInteraction.create!(
      actor: current_user,
      target: target_profile.user,
      interaction_type: "like"
    )
    
    # Check for mutual like (match)
    if mutual_like_exists?(target_profile.user)
      create_match(target_profile.user)
      render json: { status: "match", message: "It's a match!" }
    else
      render json: { status: "liked", message: "Like sent!" }
    end
  end
  
  def pass
    target_profile = Profile.find(params[:id])
    
    # Record interaction
    UserInteraction.create!(
      actor: current_user,
      target: target_profile.user,
      interaction_type: "pass"
    )
    
    render json: { status: "passed", message: "Profile passed" }
  end
  
  private
  
  def set_profile
    @profile = Profile.find(params[:id])
  end
  
  def profile_params
    params.require(:profile).permit(:bio, :location, :lat, :lng, :gender, :age, photos: [])
  end
  
  def privacy_params
    params.require(:privacy_settings).permit(:location_visible, :show_age, :show_last_seen) if params[:privacy_settings]
  end
  
  def preference_params
    params.require(:user_preferences).permit(:min_age, :max_age, :max_distance, :preferred_gender) if params[:user_preferences]
  end
  
  def ensure_own_profile
    unless @profile.user == current_user
      redirect_to profiles_path, alert: "Access denied"
    end
  end
  
  def filtered_profiles
    user_prefs = current_user.user_preferences.first
    profiles = Profile.where.not(user: current_user)
    
    # Apply user preferences
    if user_prefs
      profiles = profiles.where(age: user_prefs.min_age..user_prefs.max_age)
      profiles = profiles.where(gender: user_prefs.preferred_gender) unless user_prefs.preferred_gender == "any"
      
      # Location filtering
      if user_prefs.max_distance && current_user.profile&.lat && current_user.profile&.lng
        profiles = profiles.near([current_user.profile.lat, current_user.profile.lng], user_prefs.max_distance)
      end
    end
    
    # Exclude already interacted profiles
    interacted_user_ids = UserInteraction.where(actor: current_user).pluck(:target_id)
    profiles = profiles.where.not(user_id: interacted_user_ids)
    
    profiles.order(created_at: :desc)
  end
  
  def nearby_profiles_count
    return 0 unless current_user.profile&.lat && current_user.profile&.lng
    
    user_prefs = current_user.user_preferences.first
    max_distance = user_prefs&.max_distance || 50
    
    Profile.where.not(user: current_user)
           .near([current_user.profile.lat, current_user.profile.lng], max_distance)
           .count
  end
  
  def can_view_location?(profile)
    profile.user.privacy_settings&.location_visible != false
  end
  
  def can_view_age?(profile)
    profile.user.privacy_settings&.show_age != false
  end
  
  def can_view_last_seen?(profile)
    profile.user.privacy_settings&.show_last_seen == true
  end
  
  def user_blocked?(user)
    # Check if current user has blocked this user or vice versa
    UserInteraction.exists?(
      actor: current_user,
      target: user,
      interaction_type: "block"
    ) || UserInteraction.exists?(
      actor: user,
      target: current_user,
      interaction_type: "block"
    )
  end
  
  def can_report_user?(user)
    !SafetyReport.exists?(reporter: current_user, reported_user: user)
  end
  
  def calculate_compatibility(profile)
    # Simplified compatibility calculation
    score = 0.0
    
    # Age compatibility
    user_prefs = current_user.user_preferences.first
    if user_prefs
      age_diff = (profile.age - ((user_prefs.min_age + user_prefs.max_age) / 2)).abs
      score += [1.0 - (age_diff / 20.0), 0.0].max * 0.3
    end
    
    # Location compatibility
    if current_user.profile&.lat && current_user.profile&.lng && profile.lat && profile.lng
      distance = Geocoder::Calculations.distance_between(
        [current_user.profile.lat, current_user.profile.lng],
        [profile.lat, profile.lng]
      )
      score += [1.0 - (distance / 100.0), 0.0].max * 0.4
    end
    
    # Bio similarity (simplified)
    if current_user.profile&.bio && profile.bio
      common_words = (current_user.profile.bio.downcase.split & profile.bio.downcase.split).length
      score += [common_words / 10.0, 0.3].min * 0.3
    end
    
    (score * 100).round
  end
  
  def mutual_like_exists?(target_user)
    UserInteraction.exists?(
      actor: target_user,
      target: current_user,
      interaction_type: "like"
    )
  end
  
  def create_match(target_user)
    Match.create!(
      initiator: current_user,
      receiver: target_user,
      status: "active",
      matched_at: Time.current
    )
  end
end
EOF
  
  # Create profile model with privacy features
  cat <<EOF > app/models/profile.rb
class Profile < ApplicationRecord
  belongs_to :user
  has_many :profile_photos, dependent: :destroy
  has_many :initiated_matches, class_name: "Match", foreign_key: "initiator_id"
  has_many :received_matches, class_name: "Match", foreign_key: "receiver_id"
  
  validates :bio, presence: true, length: { minimum: 50, maximum: 500 }
  validates :location, presence: true
  validates :gender, presence: true, inclusion: { in: %w[male female non-binary other] }
  validates :age, presence: true, numericality: { greater_than: 17, less_than: 100 }
  validates :lat, :lng, presence: true, numericality: true
  
  scope :active, -> { joins(:user).where(users: { active: true }) }
  scope :by_gender, ->(gender) { where(gender: gender) }
  scope :by_age_range, ->(min, max) { where(age: min..max) }
  scope :recent, -> { order(created_at: :desc) }
  
  def display_age
    return "Age hidden" unless user.privacy_settings&.show_age != false
    age
  end
  
  def display_location
    return "Location hidden" unless user.privacy_settings&.location_visible != false
    location
  end
  
  def display_last_seen
    return nil unless user.privacy_settings&.show_last_seen == true
    user.last_seen_at&.strftime("%B %d, %Y")
  end
  
  def primary_photo
    profile_photos.where(primary: true, approved: true).first
  end
  
  def approved_photos
    profile_photos.where(approved: true).order(:created_at)
  end
  
  def match_count
    Match.where(
      "(initiator_id = ? OR receiver_id = ?) AND status = ?",
      user.id, user.id, "active"
    ).count
  end
  
  def recent_matches
    Match.where(
      "(initiator_id = ? OR receiver_id = ?) AND status = ?",
      user.id, user.id, "active"
    ).order(matched_at: :desc)
  end
  
  def distance_from(other_profile)
    return nil unless lat && lng && other_profile.lat && other_profile.lng
    
    Geocoder::Calculations.distance_between(
      [lat, lng],
      [other_profile.lat, other_profile.lng]
    ).round(1)
  end
  
  def online?
    user.last_seen_at && user.last_seen_at > 5.minutes.ago
  end
  
  def recently_active?
    user.last_seen_at && user.last_seen_at > 24.hours.ago
  end
end
EOF
  
  # Create enhanced home controller for dating
  cat <<EOF > app/controllers/home_controller.rb
class HomeController < ApplicationController
  before_action :authenticate_user!
  
  def index
    @cognitive_load = CognitiveLoadMonitor.new
    @complexity_assessment = @cognitive_load.assess_complexity(
      "Dating home with match suggestions and discovery features"
    )
    
    # Ensure user has a profile
    unless current_user.profile
      redirect_to new_profile_path, alert: "Please complete your profile first"
      return
    end
    
    # Cognitive load management: limit to 7 key elements
    @suggested_profiles = Profile.active
                                 .where.not(user: current_user)
                                 .limit(5)
    
    @recent_matches = current_user.profile.recent_matches.limit(3)
    @nearby_count = nearby_profiles_count
    
    @user_stats = {
      profile_views: UserInteraction.where(target: current_user, interaction_type: "view").count,
      likes_received: UserInteraction.where(target: current_user, interaction_type: "like").count,
      matches_count: current_user.profile.match_count
    }
    
    # Flow state tracking for dating experience
    @flow_tracker = FlowStateTracker.new
    @flow_tracker.update({
      "concentration" => 0.7,
      "challenge_skill_balance" => 0.8,
      "clear_goals" => 0.9,
      "immediate_feedback" => 0.9
    })
  end
  
  private
  
  def nearby_profiles_count
    return 0 unless current_user.profile&.lat && current_user.profile&.lng
    
    user_prefs = current_user.user_preferences.first
    max_distance = user_prefs&.max_distance || 50
    
    Profile.where.not(user: current_user)
           .near([current_user.profile.lat, current_user.profile.lng], max_distance)
           .count
  end
end
EOF
  
  # Create JavaScript for dating features
  mkdir -p app/javascript/controllers
  cat <<EOF > app/javascript/controllers/dating_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["profileCard", "likeButton", "passButton", "matchModal"]
  static values = { userId: Number }
  
  connect() {
    this.setupSwipeGestures()
  }
  
  like(event) {
    event.preventDefault()
    const profileId = this.profileCardTarget.dataset.profileId
    
    this.sendInteraction(profileId, "like")
      .then(response => {
        if (response.status === "match") {
          this.showMatchModal(response.message)
        } else {
          this.showFeedback(response.message, "positive")
        }
        this.nextProfile()
      })
      .catch(error => {
        this.showFeedback("Error processing like", "negative")
      })
  }
  
  pass(event) {
    event.preventDefault()
    const profileId = this.profileCardTarget.dataset.profileId
    
    this.sendInteraction(profileId, "pass")
      .then(response => {
        this.showFeedback(response.message, "neutral")
        this.nextProfile()
      })
      .catch(error => {
        this.showFeedback("Error processing pass", "negative")
      })
  }
  
  setupSwipeGestures() {
    if (!this.hasProfileCardTarget) return
    
    let startX = 0
    let startY = 0
    let currentX = 0
    let currentY = 0
    
    this.profileCardTarget.addEventListener("touchstart", (e) => {
      startX = e.touches[0].clientX
      startY = e.touches[0].clientY
    })
    
    this.profileCardTarget.addEventListener("touchmove", (e) => {
      currentX = e.touches[0].clientX
      currentY = e.touches[0].clientY
      
      const deltaX = currentX - startX
      const deltaY = currentY - startY
      
      // Visual feedback for swipe
      this.profileCardTarget.style.transform = \`translateX(\${deltaX}px) rotate(\${deltaX * 0.1}deg)\`
      
      // Color feedback
      if (Math.abs(deltaX) > 50) {
        if (deltaX > 0) {
          this.profileCardTarget.style.backgroundColor = "rgba(0, 255, 0, 0.1)"
        } else {
          this.profileCardTarget.style.backgroundColor = "rgba(255, 0, 0, 0.1)"
        }
      } else {
        this.profileCardTarget.style.backgroundColor = "transparent"
      }
    })
    
    this.profileCardTarget.addEventListener("touchend", (e) => {
      const deltaX = currentX - startX
      const deltaY = currentY - startY
      
      // Reset visual state
      this.profileCardTarget.style.transform = "translateX(0) rotate(0deg)"
      this.profileCardTarget.style.backgroundColor = "transparent"
      
      // Determine swipe action
      if (Math.abs(deltaX) > 100) {
        if (deltaX > 0) {
          this.like(e)
        } else {
          this.pass(e)
        }
      }
    })
  }
  
  sendInteraction(profileId, type) {
    return fetch(\`/profiles/\${profileId}/\${type}\`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
      }
    }).then(response => response.json())
  }
  
  showMatchModal(message) {
    if (this.hasMatchModalTarget) {
      this.matchModalTarget.querySelector(".message").textContent = message
      this.matchModalTarget.classList.remove("hidden")
    }
  }
  
  showFeedback(message, type) {
    const feedback = document.createElement("div")
    feedback.className = \`feedback \${type}\`
    feedback.textContent = message
    
    document.body.appendChild(feedback)
    
    setTimeout(() => {
      feedback.remove()
    }, 3000)
  }
  
  nextProfile() {
    // Load next profile (would integrate with backend)
    setTimeout(() => {
      window.location.reload()
    }, 1000)
  }
  
  reportUser(event) {
    event.preventDefault()
    const profileId = this.profileCardTarget.dataset.profileId
    
    if (confirm("Are you sure you want to report this user?")) {
      fetch(\`/profiles/\${profileId}/report\`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
        }
      }).then(response => {
        if (response.ok) {
          this.showFeedback("User reported successfully", "positive")
          this.nextProfile()
        } else {
          this.showFeedback("Error reporting user", "negative")
        }
      })
    }
  }
  
  blockUser(event) {
    event.preventDefault()
    const profileId = this.profileCardTarget.dataset.profileId
    
    if (confirm("Are you sure you want to block this user?")) {
      this.sendInteraction(profileId, "block")
        .then(response => {
          this.showFeedback("User blocked successfully", "positive")
          this.nextProfile()
        })
        .catch(error => {
          this.showFeedback("Error blocking user", "negative")
        })
    }
  }
}
EOF
  
  log "Dating application code generation completed" "INFO"
}

# Override main to use enhanced installation
main() {
  log "Starting Brgen Dating installation with cognitive framework" "INFO"
  
  # Use enhanced shared installation
  source "../../__shared_enhanced.sh"
  
  # Run the main installation process
  if command -v initialize_application > /dev/null 2>&1; then
    # Run enhanced installation
    initialize_application
    setup_rails_application
    setup_database
    setup_cognitive_framework
    setup_authentication
    setup_security
    generate_application_code  # This will use our Dating-specific implementation
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

bin/rails generate scaffold Profile user:references bio:text location:string lat:decimal lng:decimal gender:string age:integer photos:attachments
bin/rails generate scaffold Match initiator:references{polymorphic} receiver:references{polymorphic} status:string

cat <<EOF > app/reflexes/profiles_infinite_scroll_reflex.rb
class ProfilesInfiniteScrollReflex < InfiniteScrollReflex
  def load_more
    @pagy, @collection = pagy(Profile.all.order(created_at: :desc), page: page)
    super
  end
end
EOF

cat <<EOF > app/reflexes/matches_infinite_scroll_reflex.rb
class MatchesInfiniteScrollReflex < InfiniteScrollReflex
  def load_more
    @pagy, @collection = pagy(Match.where(initiator: current_user.profile).or(Match.where(receiver: current_user.profile)).order(created_at: :desc), page: page)
    super
  end
end
EOF

cat <<EOF > app/javascript/controllers/mapbox_controller.js
import { Controller } from "@hotwired/stimulus"
import mapboxgl from "mapbox-gl"
import MapboxGeocoder from "mapbox-gl-geocoder"

export default class extends Controller {
  static values = { apiKey: String, profiles: Array }

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
    this.profilesValue.forEach(profile => {
      new mapboxgl.Marker({ color: "#e91e63" })
        .setLngLat([profile.lng, profile.lat])
        .setPopup(new mapboxgl.Popup().setHTML(\`<h3>\${profile.user.email}</h3><p>\${profile.bio}</p>\`))
        .addTo(this.map)
    })
  }
}
EOF

cat <<EOF > app/controllers/profiles_controller.rb
class ProfilesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_profile, only: [:show, :edit, :update, :destroy]

  def index
    @pagy, @profiles = pagy(Profile.all.order(created_at: :desc)) unless @stimulus_reflex
  end

  def show
  end

  def new
    @profile = Profile.new
  end

  def create
    @profile = Profile.new(profile_params)
    @profile.user = current_user
    if @profile.save
      respond_to do |format|
        format.html { redirect_to profiles_path, notice: t("brgen_dating.profile_created") }
        format.turbo_stream
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @profile.update(profile_params)
      respond_to do |format|
        format.html { redirect_to profiles_path, notice: t("brgen_dating.profile_updated") }
        format.turbo_stream
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @profile.destroy
    respond_to do |format|
      format.html { redirect_to profiles_path, notice: t("brgen_dating.profile_deleted") }
      format.turbo_stream
    end
  end

  private

  def set_profile
    @profile = Profile.find(params[:id])
    redirect_to profiles_path, alert: t("brgen_dating.not_authorized") unless @profile.user == current_user || current_user&.admin?
  end

  def profile_params
    params.require(:profile).permit(:bio, :location, :lat, :lng, :gender, :age, photos: [])
  end
end
EOF

cat <<EOF > app/controllers/matches_controller.rb
class MatchesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_match, only: [:show, :edit, :update, :destroy]

  def index
    @pagy, @matches = pagy(Match.where(initiator: current_user.profile).or(Match.where(receiver: current_user.profile)).order(created_at: :desc)) unless @stimulus_reflex
  end

  def show
  end

  def new
    @match = Match.new
  end

  def create
    @match = Match.new(match_params)
    @match.initiator = current_user.profile
    if @match.save
      respond_to do |format|
        format.html { redirect_to matches_path, notice: t("brgen_dating.match_created") }
        format.turbo_stream
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @match.update(match_params)
      respond_to do |format|
        format.html { redirect_to matches_path, notice: t("brgen_dating.match_updated") }
        format.turbo_stream
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @match.destroy
    respond_to do |format|
      format.html { redirect_to matches_path, notice: t("brgen_dating.match_deleted") }
      format.turbo_stream
    end
  end

  private

  def set_match
    @match = Match.where(initiator: current_user.profile).or(Match.where(receiver: current_user.profile)).find(params[:id])
    redirect_to matches_path, alert: t("brgen_dating.not_authorized") unless @match.initiator == current_user.profile || @match.receiver == current_user.profile || current_user&.admin?
  end

  def match_params
    params.require(:match).permit(:receiver_id, :status)
  end
end
EOF

cat <<EOF > app/controllers/home_controller.rb
class HomeController < ApplicationController
  def index
    @pagy, @posts = pagy(Post.all.order(created_at: :desc), items: 10) unless @stimulus_reflex
    @profiles = Profile.all.order(created_at: :desc).limit(5)
  end
end
EOF

mkdir -p app/views/brgen_dating_logo

cat <<EOF > app/views/brgen_dating_logo/_logo.html.erb
<%= tag.svg xmlns: "http://www.w3.org/2000/svg", viewBox: "0 0 100 50", role: "img", class: "logo", "aria-label": t("brgen_dating.logo_alt") do %>
  <%= tag.title t("brgen_dating.logo_title", default: "Brgen Dating Logo") %>
  <%= tag.path d: "M50 15 C70 5, 90 25, 50 45 C10 25, 30 5, 50 15", fill: "#e91e63", stroke: "#1a73e8", "stroke-width": "2" %>
<% end %>
EOF

cat <<EOF > app/views/shared/_header.html.erb
<%= tag.header role: "banner" do %>
  <%= render partial: "brgen_dating_logo/logo" %>
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

cat <<EOF > app/views/home/index.html.erb
<% content_for :title, t("brgen_dating.home_title") %>
<% content_for :description, t("brgen_dating.home_description") %>
<% content_for :keywords, t("brgen_dating.home_keywords", default: "brgen dating, profiles, matchmaking") %>
<% content_for :schema do %>
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "WebPage",
    "name": "<%= t('brgen_dating.home_title') %>",
    "description": "<%= t('brgen_dating.home_description') %>",
    "url": "<%= request.original_url %>",
    "publisher": {
      "@type": "Organization",
      "name": "Brgen Dating",
      "logo": {
        "@type": "ImageObject",
        "url": "<%= image_url('brgen_dating_logo.svg') %>"
      }
    }
  }
  </script>
<% end %>
<%= render "shared/header" %>
<%= tag.main role: "main" do %>
  <%= tag.section aria-labelledby: "post-heading" do %>
    <%= tag.h1 t("brgen_dating.post_title"), id: "post-heading" %>
    <%= tag.div data: { turbo_frame: "notices" } do %>
      <%= render "shared/notices" %>
    <% end %>
    <%= render partial: "posts/form", locals: { post: Post.new } %>
  <% end %>
  <%= tag.section aria-labelledby: "map-heading" do %>
    <%= tag.h2 t("brgen_dating.map_title"), id: "map-heading" %>
    <%= tag.div id: "map" data: { controller: "mapbox", "mapbox-api-key-value": ENV["MAPBOX_API_KEY"], "mapbox-profiles-value": @profiles.to_json } %>
  <% end %>
  <%= render partial: "shared/search", locals: { model: "Profile", field: "bio" } %>
  <%= tag.section aria-labelledby: "profiles-heading" do %>
    <%= tag.h2 t("brgen_dating.profiles_title"), id: "profiles-heading" %>
    <%= link_to t("brgen_dating.new_profile"), new_profile_path, class: "button", "aria-label": t("brgen_dating.new_profile") if current_user %>
    <%= turbo_frame_tag "profiles" data: { controller: "infinite-scroll" } do %>
      <% @profiles.each do |profile| %>
        <%= render partial: "profiles/card", locals: { profile: profile } %>
      <% end %>
      <%= tag.div id: "sentinel", class: "hidden", data: { reflex: "ProfilesInfiniteScroll#load_more", next_page: @pagy.next || 2 } %>
    <% end %>
    <%= tag.button t("brgen_dating.load_more"), id: "load-more", data: { reflex: "click->ProfilesInfiniteScroll#load_more", "next-page": @pagy.next || 2, "reflex-root": "#load-more" }, class: @pagy&.next ? "" : "hidden", "aria-label": t("brgen_dating.load_more") %>
  <% end %>
  <%= tag.section aria-labelledby: "posts-heading" do %>
    <%= tag.h2 t("brgen_dating.posts_title"), id: "posts-heading" %>
    <%= turbo_frame_tag "posts" data: { controller: "infinite-scroll" } do %>
      <% @posts.each do |post| %>
        <%= render partial: "posts/card", locals: { post: post } %>
      <% end %>
      <%= tag.div id: "sentinel", class: "hidden", data: { reflex: "PostsInfiniteScroll#load_more", next_page: @pagy.next || 2 } %>
    <% end %>
    <%= tag.button t("brgen_dating.load_more"), id: "load-more", data: { reflex: "click->PostsInfiniteScroll#load_more", "next-page": @pagy.next || 2, "reflex-root": "#load-more" }, class: @pagy&.next ? "" : "hidden", "aria-label": t("brgen_dating.load_more") %>
  <% end %>
  <%= render partial: "shared/chat" %>
<% end %>
<%= render "shared/footer" %>
EOF

cat <<EOF > app/views/profiles/index.html.erb
<% content_for :title, t("brgen_dating.profiles_title") %>
<% content_for :description, t("brgen_dating.profiles_description") %>
<% content_for :keywords, t("brgen_dating.profiles_keywords", default: "brgen dating, profiles, matchmaking") %>
<% content_for :schema do %>
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "WebPage",
    "name": "<%= t('brgen_dating.profiles_title') %>",
    "description": "<%= t('brgen_dating.profiles_description') %>",
    "url": "<%= request.original_url %>",
    "hasPart": [
      <% @profiles.each do |profile| %>
      {
        "@type": "Person",
        "name": "<%= profile.user.email %>",
        "description": "<%= profile.bio&.truncate(160) %>",
        "address": {
          "@type": "PostalAddress",
          "addressLocality": "<%= profile.location %>"
        }
      }<%= "," unless profile == @profiles.last %>
      <% end %>
    ]
  }
  </script>
<% end %>
<%= render "shared/header" %>
<%= tag.main role: "main" do %>
  <%= tag.section aria-labelledby: "profiles-heading" do %>
    <%= tag.h1 t("brgen_dating.profiles_title"), id: "profiles-heading" %>
    <%= tag.div data: { turbo_frame: "notices" } do %>
      <%= render "shared/notices" %>
    <% end %>
    <%= link_to t("brgen_dating.new_profile"), new_profile_path, class: "button", "aria-label": t("brgen_dating.new_profile") if current_user %>
    <%= turbo_frame_tag "profiles" data: { controller: "infinite-scroll" } do %>
      <% @profiles.each do |profile| %>
        <%= render partial: "profiles/card", locals: { profile: profile } %>
      <% end %>
      <%= tag.div id: "sentinel", class: "hidden", data: { reflex: "ProfilesInfiniteScroll#load_more", next_page: @pagy.next || 2 } %>
    <% end %>
    <%= tag.button t("brgen_dating.load_more"), id: "load-more", data: { reflex: "click->ProfilesInfiniteScroll#load_more", "next-page": @pagy.next || 2, "reflex-root": "#load-more" }, class: @pagy&.next ? "" : "hidden", "aria-label": t("brgen_dating.load_more") %>
  <% end %>
  <%= render partial: "shared/search", locals: { model: "Profile", field: "bio" } %>
<% end %>
<%= render "shared/footer" %>
EOF

cat <<EOF > app/views/profiles/_card.html.erb
<%= turbo_frame_tag dom_id(profile) do %>
  <%= tag.article class: "post-card", id: dom_id(profile), role: "article" do %>
    <%= tag.div class: "post-header" do %>
      <%= tag.span t("brgen_dating.posted_by", user: profile.user.email) %>
      <%= tag.span profile.created_at.strftime("%Y-%m-%d %H:%M") %>
    <% end %>
    <%= tag.h2 profile.user.email %>
    <%= tag.p profile.bio %>
    <%= tag.p t("brgen_dating.profile_location", location: profile.location) %>
    <%= tag.p t("brgen_dating.profile_gender", gender: profile.gender) %>
    <%= tag.p t("brgen_dating.profile_age", age: profile.age) %>
    <% if profile.photos.attached? %>
      <% profile.photos.each do |photo| %>
        <%= image_tag photo, style: "max-width: 200px;", alt: t("brgen_dating.profile_photo", email: profile.user.email) %>
      <% end %>
    <% end %>
    <%= render partial: "shared/vote", locals: { votable: profile } %>
    <%= tag.p class: "post-actions" do %>
      <%= link_to t("brgen_dating.view_profile"), profile_path(profile), "aria-label": t("brgen_dating.view_profile") %>
      <%= link_to t("brgen_dating.edit_profile"), edit_profile_path(profile), "aria-label": t("brgen_dating.edit_profile") if profile.user == current_user || current_user&.admin? %>
      <%= button_to t("brgen_dating.delete_profile"), profile_path(profile), method: :delete, data: { turbo_confirm: t("brgen_dating.confirm_delete") }, form: { data: { turbo_frame: "_top" } }, "aria-label": t("brgen_dating.delete_profile") if profile.user == current_user || current_user&.admin? %>
    <% end %>
  <% end %>
<% end %>
EOF

cat <<EOF > app/views/profiles/_form.html.erb
<%= form_with model: profile, local: true, data: { controller: "character-counter form-validation", turbo: true } do |form| %>
  <%= tag.div data: { turbo_frame: "notices" } do %>
    <%= render "shared/notices" %>
  <% end %>
  <% if profile.errors.any? %>
    <%= tag.div role: "alert" do %>
      <%= tag.p t("brgen_dating.errors", count: profile.errors.count) %>
      <%= tag.ul do %>
        <% profile.errors.full_messages.each do |msg| %>
          <%= tag.li msg %>
        <% end %>
      <% end %>
    <% end %>
  <% end %>
  <%= tag.fieldset do %>
    <%= form.label :bio, t("brgen_dating.profile_bio"), "aria-required": true %>
    <%= form.text_area :bio, required: true, data: { "character-counter-target": "input", "textarea-autogrow-target": "input", "form-validation-target": "input", action: "input->character-counter#count input->textarea-autogrow#resize input->form-validation#validate" }, title: t("brgen_dating.profile_bio_help") %>
    <%= tag.span data: { "character-counter-target": "count" } %>
    <%= tag.span class: "error-message" data: { "form-validation-target": "error", for: "profile_bio" } %>
  <% end %>
  <%= tag.fieldset do %>
    <%= form.label :location, t("brgen_dating.profile_location"), "aria-required": true %>
    <%= form.text_field :location, required: true, data: { "form-validation-target": "input", action: "input->form-validation#validate" }, title: t("brgen_dating.profile_location_help") %>
    <%= tag.span class: "error-message" data: { "form-validation-target": "error", for: "profile_location" } %>
  <% end %>
  <%= tag.fieldset do %>
    <%= form.label :lat, t("brgen_dating.profile_lat"), "aria-required": true %>
    <%= form.number_field :lat, required: true, step: "any", data: { "form-validation-target": "input", action: "input->form-validation#validate" }, title: t("brgen_dating.profile_lat_help") %>
    <%= tag.span class: "error-message" data: { "form-validation-target": "error", for: "profile_lat" } %>
  <% end %>
  <%= tag.fieldset do %>
    <%= form.label :lng, t("brgen_dating.profile_lng"), "aria-required": true %>
    <%= form.number_field :lng, required: true, step: "any", data: { "form-validation-target": "input", action: "input->form-validation#validate" }, title: t("brgen_dating.profile_lng_help") %>
    <%= tag.span class: "error-message" data: { "form-validation-target": "error", for: "profile_lng" } %>
  <% end %>
  <%= tag.fieldset do %>
    <%= form.label :gender, t("brgen_dating.profile_gender"), "aria-required": true %>
    <%= form.text_field :gender, required: true, data: { "form-validation-target": "input", action: "input->form-validation#validate" }, title: t("brgen_dating.profile_gender_help") %>
    <%= tag.span class: "error-message" data: { "form-validation-target": "error", for: "profile_gender" } %>
  <% end %>
  <%= tag.fieldset do %>
    <%= form.label :age, t("brgen_dating.profile_age"), "aria-required": true %>
    <%= form.number_field :age, required: true, data: { "form-validation-target": "input", action: "input->form-validation#validate" }, title: t("brgen_dating.profile_age_help") %>
    <%= tag.span class: "error-message" data: { "form-validation-target": "error", for: "profile_age" } %>
  <% end %>
  <%= tag.fieldset do %>
    <%= form.label :photos, t("brgen_dating.profile_photos") %>
    <%= form.file_field :photos, multiple: true, accept: "image/*", data: { controller: "file-preview", "file-preview-target": "input" } %>
    <% if profile.photos.attached? %>
      <% profile.photos.each do |photo| %>
        <%= image_tag photo, style: "max-width: 200px;", alt: t("brgen_dating.profile_photo", email: profile.user.email) %>
      <% end %>
    <% end %>
    <%= tag.div data: { "file-preview-target": "preview" }, style: "display: none;" %>
  <% end %>
  <%= form.submit t("brgen_dating.#{profile.persisted? ? 'update' : 'create'}_profile"), data: { turbo_submits_with: t("brgen_dating.#{profile.persisted? ? 'updating' : 'creating'}_profile") } %>
<% end %>
EOF

cat <<EOF > app/views/profiles/new.html.erb
<% content_for :title, t("brgen_dating.new_profile_title") %>
<% content_for :description, t("brgen_dating.new_profile_description") %>
<% content_for :keywords, t("brgen_dating.new_profile_keywords", default: "add profile, brgen dating, matchmaking") %>
<% content_for :schema do %>
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "WebPage",
    "name": "<%= t('brgen_dating.new_profile_title') %>",
    "description": "<%= t('brgen_dating.new_profile_description') %>",
    "url": "<%= request.original_url %>"
  }
  </script>
<% end %>
<%= render "shared/header" %>
<%= tag.main role: "main" do %>
  <%= tag.section aria-labelledby: "new-profile-heading" do %>
    <%= tag.h1 t("brgen_dating.new_profile_title"), id: "new-profile-heading" %>
    <%= render partial: "profiles/form", locals: { profile: @profile } %>
  <% end %>
<% end %>
<%= render "shared/footer" %>
EOF

cat <<EOF > app/views/profiles/edit.html.erb
<% content_for :title, t("brgen_dating.edit_profile_title") %>
<% content_for :description, t("brgen_dating.edit_profile_description") %>
<% content_for :keywords, t("brgen_dating.edit_profile_keywords", default: "edit profile, brgen dating, matchmaking") %>
<% content_for :schema do %>
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "WebPage",
    "name": "<%= t('brgen_dating.edit_profile_title') %>",
    "description": "<%= t('brgen_dating.edit_profile_description') %>",
    "url": "<%= request.original_url %>"
  }
  </script>
<% end %>
<%= render "shared/header" %>
<%= tag.main role: "main" do %>
  <%= tag.section aria-labelledby: "edit-profile-heading" do %>
    <%= tag.h1 t("brgen_dating.edit_profile_title"), id: "edit-profile-heading" %>
    <%= render partial: "profiles/form", locals: { profile: @profile } %>
  <% end %>
<% end %>
<%= render "shared/footer" %>
EOF

cat <<EOF > app/views/profiles/show.html.erb
<% content_for :title, @profile.user.email %>
<% content_for :description, @profile.bio&.truncate(160) %>
<% content_for :keywords, t("brgen_dating.profile_keywords", email: @profile.user.email, default: "profile, #{@profile.user.email}, brgen dating, matchmaking") %>
<% content_for :schema do %>
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "Person",
    "name": "<%= @profile.user.email %>",
    "description": "<%= @profile.bio&.truncate(160) %>",
    "address": {
      "@type": "PostalAddress",
      "addressLocality": "<%= @profile.location %>"
    }
  }
  </script>
<% end %>
<%= render "shared/header" %>
<%= tag.main role: "main" do %>
  <%= tag.section aria-labelledby: "profile-heading" class: "post-card" do %>
    <%= tag.div data: { turbo_frame: "notices" } do %>
      <%= render "shared/notices" %>
    <% end %>
    <%= tag.h1 @profile.user.email, id: "profile-heading" %>
    <%= render partial: "profiles/card", locals: { profile: @profile } %>
  <% end %>
<% end %>
<%= render "shared/footer" %>
EOF

cat <<EOF > app/views/matches/index.html.erb
<% content_for :title, t("brgen_dating.matches_title") %>
<% content_for :description, t("brgen_dating.matches_description") %>
<% content_for :keywords, t("brgen_dating.matches_keywords", default: "brgen dating, matches, matchmaking") %>
<% content_for :schema do %>
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "WebPage",
    "name": "<%= t('brgen_dating.matches_title') %>",
    "description": "<%= t('brgen_dating.matches_description') %>",
    "url": "<%= request.original_url %>"
  }
  </script>
<% end %>
<%= render "shared/header" %>
<%= tag.main role: "main" do %>
  <%= tag.section aria-labelledby: "matches-heading" do %>
    <%= tag.h1 t("brgen_dating.matches_title"), id: "matches-heading" %>
    <%= tag.div data: { turbo_frame: "notices" } do %>
      <%= render "shared/notices" %>
    <% end %>
    <%= link_to t("brgen_dating.new_match"), new_match_path, class: "button", "aria-label": t("brgen_dating.new_match") %>
    <%= turbo_frame_tag "matches" data: { controller: "infinite-scroll" } do %>
      <% @matches.each do |match| %>
        <%= render partial: "matches/card", locals: { match: match } %>
      <% end %>
      <%= tag.div id: "sentinel", class: "hidden", data: { reflex: "MatchesInfiniteScroll#load_more", next_page: @pagy.next || 2 } %>
    <% end %>
    <%= tag.button t("brgen_dating.load_more"), id: "load-more", data: { reflex: "click->MatchesInfiniteScroll#load_more", "next-page": @pagy.next || 2, "reflex-root": "#load-more" }, class: @pagy&.next ? "" : "hidden", "aria-label": t("brgen_dating.load_more") %>
  <% end %>
<% end %>
<%= render "shared/footer" %>
EOF

cat <<EOF > app/views/matches/_card.html.erb
<%= turbo_frame_tag dom_id(match) do %>
  <%= tag.article class: "post-card", id: dom_id(match), role: "article" do %>
    <%= tag.div class: "post-header" do %>
      <%= tag.span t("brgen_dating.initiated_by", user: match.initiator.user.email) %>
      <%= tag.span match.created_at.strftime("%Y-%m-%d %H:%M") %>
    <% end %>
    <%= tag.h2 match.receiver.user.email %>
    <%= tag.p t("brgen_dating.match_status", status: match.status) %>
    <%= render partial: "shared/vote", locals: { votable: match } %>
    <%= tag.p class: "post-actions" do %>
      <%= link_to t("brgen_dating.view_match"), match_path(match), "aria-label": t("brgen_dating.view_match") %>
      <%= link_to t("brgen_dating.edit_match"), edit_match_path(match), "aria-label": t("brgen_dating.edit_match") if match.initiator == current_user.profile || match.receiver == current_user.profile || current_user&.admin? %>
      <%= button_to t("brgen_dating.delete_match"), match_path(match), method: :delete, data: { turbo_confirm: t("brgen_dating.confirm_delete") }, form: { data: { turbo_frame: "_top" } }, "aria-label": t("brgen_dating.delete_match") if match.initiator == current_user.profile || match.receiver == current_user.profile || current_user&.admin? %>
    <% end %>
  <% end %>
<% end %>
EOF

cat <<EOF > app/views/matches/_form.html.erb
<%= form_with model: match, local: true, data: { controller: "form-validation", turbo: true } do |form| %>
  <%= tag.div data: { turbo_frame: "notices" } do %>
    <%= render "shared/notices" %>
  <% end %>
  <% if match.errors.any? %>
    <%= tag.div role: "alert" do %>
      <%= tag.p t("brgen_dating.errors", count: match.errors.count) %>
      <%= tag.ul do %>
        <% match.errors.full_messages.each do |msg| %>
          <%= tag.li msg %>
        <% end %>
      <% end %>
    <% end %>
  <% end %>
  <%= tag.fieldset do %>
    <%= form.label :receiver_id, t("brgen_dating.match_receiver"), "aria-required": true %>
    <%= form.collection_select :receiver_id, Profile.all, :id, :user_email, { prompt: t("brgen_dating.receiver_prompt") }, required: true %>
    <%= tag.span class: "error-message" data: { "form-validation-target": "error", for: "match_receiver_id" } %>
  <% end %>
  <%= tag.fieldset do %>
    <%= form.label :status, t("brgen_dating.match_status"), "aria-required": true %>
    <%= form.select :status, ["pending", "accepted", "rejected"], { prompt: t("brgen_dating.status_prompt"), selected: match.status }, required: true %>
    <%= tag.span class: "error-message" data: { "form-validation-target": "error", for: "match_status" } %>
  <% end %>
  <%= form.submit t("brgen_dating.#{match.persisted? ? 'update' : 'create'}_match"), data: { turbo_submits_with: t("brgen_dating.#{match.persisted? ? 'updating' : 'creating'}_match") } %>
<% end %>
EOF

cat <<EOF > app/views/matches/new.html.erb
<% content_for :title, t("brgen_dating.new_match_title") %>
<% content_for :description, t("brgen_dating.new_match_description") %>
<% content_for :keywords, t("brgen_dating.new_match_keywords", default: "add match, brgen dating, matchmaking") %>
<% content_for :schema do %>
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "WebPage",
    "name": "<%= t('brgen_dating.new_match_title') %>",
    "description": "<%= t('brgen_dating.new_match_description') %>",
    "url": "<%= request.original_url %>"
  }
  </script>
<% end %>
<%= render "shared/header" %>
<%= tag.main role: "main" do %>
  <%= tag.section aria-labelledby: "new-match-heading" do %>
    <%= tag.h1 t("brgen_dating.new_match_title"), id: "new-match-heading" %>
    <%= render partial: "matches/form", locals: { match: @match } %>
  <% end %>
<% end %>
<%= render "shared/footer" %>
EOF

cat <<EOF > app/views/matches/edit.html.erb
<% content_for :title, t("brgen_dating.edit_match_title") %>
<% content_for :description, t("brgen_dating.edit_match_description") %>
<% content_for :keywords, t("brgen_dating.edit_match_keywords", default: "edit match, brgen dating, matchmaking") %>
<% content_for :schema do %>
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "WebPage",
    "name": "<%= t('brgen_dating.edit_match_title') %>",
    "description": "<%= t('brgen_dating.edit_match_description') %>",
    "url": "<%= request.original_url %>"
  }
  </script>
<% end %>
<%= render "shared/header" %>
<%= tag.main role: "main" do %>
  <%= tag.section aria-labelledby: "edit-match-heading" do %>
    <%= tag.h1 t("brgen_dating.edit_match_title"), id: "edit-match-heading" %>
    <%= render partial: "matches/form", locals: { match: @match } %>
  <% end %>
<% end %>
<%= render "shared/footer" %>
EOF

cat <<EOF > app/views/matches/show.html.erb
<% content_for :title, t("brgen_dating.match_title", receiver: @match.receiver.user.email) %>
<% content_for :description, t("brgen_dating.match_description", receiver: @match.receiver.user.email) %>
<% content_for :keywords, t("brgen_dating.match_keywords", receiver: @match.receiver.user.email, default: "match, #{@match.receiver.user.email}, brgen dating, matchmaking") %>
<% content_for :schema do %>
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "Person",
    "name": "<%= @match.receiver.user.email %>",
    "description": "<%= @match.receiver.bio&.truncate(160) %>"
  }
  </script>
<% end %>
<%= render "shared/header" %>
<%= tag.main role: "main" do %>
  <%= tag.section aria-labelledby: "match-heading" class: "post-card" do %>
    <%= tag.div data: { turbo_frame: "notices" } do %>
      <%= render "shared/notices" %>
    <% end %>
    <%= tag.h1 t("brgen_dating.match_title", receiver: @match.receiver.user.email), id: "match-heading" %>
    <%= render partial: "matches/card", locals: { match: @match } %>
  <% end %>
<% end %>
<%= render "shared/footer" %>
EOF

generate_turbo_views "profiles" "profile"
generate_turbo_views "matches" "match"

commit "Brgen Dating setup complete: Location-based dating platform with Mapbox, live search, and anonymous features"

log "Brgen Dating setup complete. Run 'bin/falcon-host' with PORT set to start on OpenBSD."

# Change Log:
# - Aligned with master.json v6.5.0: Two-space indents, double quotes, heredocs, Strunk & White comments.
# - Used Rails 8 conventions, Hotwire, Turbo Streams, Stimulus Reflex, I18n, and Falcon.
# - Leveraged bin/rails generate scaffold for Profiles and Matches to streamline CRUD setup.
# - Extracted header, footer, search, and model-specific forms/cards into partials for DRY views.
# - Included Mapbox for profile locations, live search, infinite scroll, and anonymous posting/chat via shared utilities.
# - Ensured NNG principles, SEO, schema data, and minimal flat design compliance.
# - Finalized for unprivileged user on OpenBSD 7.5.