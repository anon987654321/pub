#!/usr/bin/env zsh
# BlogNet: Multi-domain blog network with cognitive framework implementation
# Master.json v10.7.0 compliance with zero-trust security

set -e
setopt extended_glob null_glob

# === COGNITIVE FRAMEWORK CONFIGURATION ===
APP_NAME="blognet"
BASE_DIR="/home/dev/rails"
BRGEN_IP="46.23.95.45"

# Source enhanced shared functionality
source "./__shared_enhanced.sh"

# === BLOGNET-SPECIFIC CONFIGURATION ===
generate_application_code() {
  phase_transition "blognet_code_generation" "Creating multi-domain blog network features"
  
  # Generate models with cognitive constraints (7 concepts max)
  bin/rails generate scaffold BlogPost title:string content:text author:string category:string domain:string user:references
  bin/rails generate scaffold Comment content:text user:references blog_post:references
  bin/rails generate scaffold Category name:string description:text domain:string
  bin/rails generate model Domain name:string description:text active:boolean
  bin/rails generate model BlogSubscription user:references domain:references
  bin/rails generate model ContentModeration blog_post:references status:string moderator:references
  bin/rails generate model AnalyticsEvent event_type:string domain:string data:text
  
  # Database migrations
  bin/rails db:migrate
  
  # Create cognitive-aware controllers
  cat <<EOF > app/controllers/blog_posts_controller.rb
class BlogPostsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_blog_post, only: [:show, :edit, :update, :destroy]
  before_action :validate_domain, only: [:create, :update]
  
  def index
    @cognitive_load = CognitiveLoadMonitor.new
    @complexity_assessment = @cognitive_load.assess_complexity(
      "Blog post listing with domain filtering and content discovery"
    )
    
    # Cognitive load management: limit to 7 items
    @pagy, @blog_posts = pagy(filtered_posts.order(created_at: :desc), items: 7)
    @domains = Domain.where(active: true).limit(5)
  end
  
  def show
    @cognitive_load = CognitiveLoadMonitor.new
    @complexity_assessment = @cognitive_load.assess_complexity(
      "Individual blog post with comments and related content"
    )
    
    # Track analytics
    AnalyticsEvent.create!(
      event_type: "blog_post_view",
      domain: @blog_post.domain,
      data: { post_id: @blog_post.id, user_id: current_user&.id }.to_json
    )
    
    @related_posts = BlogPost.where(domain: @blog_post.domain)
                             .where.not(id: @blog_post.id)
                             .limit(3)
  end
  
  def new
    @blog_post = BlogPost.new
    @cognitive_load = CognitiveLoadMonitor.new
    @complexity_assessment = @cognitive_load.assess_complexity(
      "Blog post creation with rich text editor and domain selection"
    )
    
    @domains = Domain.where(active: true)
  end
  
  def create
    @blog_post = BlogPost.new(blog_post_params)
    @blog_post.user = current_user
    @blog_post.author = current_user.email
    
    if @blog_post.save
      # Queue for content moderation
      ContentModerationJob.perform_later(@blog_post)
      
      respond_to do |format|
        format.html { redirect_to blog_posts_path, notice: "Blog post created successfully!" }
        format.turbo_stream
      end
    else
      @domains = Domain.where(active: true)
      render :new, status: :unprocessable_entity
    end
  end
  
  def edit
    @cognitive_load = CognitiveLoadMonitor.new
    @complexity_assessment = @cognitive_load.assess_complexity(
      "Blog post editing with content validation and domain management"
    )
    
    @domains = Domain.where(active: true)
  end
  
  def update
    if @blog_post.update(blog_post_params)
      respond_to do |format|
        format.html { redirect_to blog_posts_path, notice: "Blog post updated successfully!" }
        format.turbo_stream
      end
    else
      @domains = Domain.where(active: true)
      render :edit, status: :unprocessable_entity
    end
  end
  
  def destroy
    @blog_post.destroy
    respond_to do |format|
      format.html { redirect_to blog_posts_path, notice: "Blog post deleted successfully!" }
      format.turbo_stream
    end
  end
  
  private
  
  def set_blog_post
    @blog_post = BlogPost.find(params[:id])
    unless @blog_post.user == current_user || current_user&.admin?
      redirect_to blog_posts_path, alert: "Access denied"
    end
  end
  
  def blog_post_params
    params.require(:blog_post).permit(:title, :content, :category, :domain)
  end
  
  def filtered_posts
    posts = BlogPost.all
    posts = posts.where(domain: params[:domain]) if params[:domain].present?
    posts = posts.where(category: params[:category]) if params[:category].present?
    posts
  end
  
  def validate_domain
    domain = params[:blog_post][:domain]
    unless Domain.where(name: domain, active: true).exists?
      redirect_to blog_posts_path, alert: "Invalid domain selected"
    end
  end
end
EOF
  
  # Create domain-aware blog model
  cat <<EOF > app/models/blog_post.rb
class BlogPost < ApplicationRecord
  belongs_to :user
  has_many :comments, dependent: :destroy
  has_many :content_moderations, dependent: :destroy
  has_many :analytics_events, dependent: :destroy
  
  validates :title, presence: true, length: { minimum: 5, maximum: 200 }
  validates :content, presence: true, length: { minimum: 50, maximum: 10000 }
  validates :category, presence: true
  validates :domain, presence: true
  validates :author, presence: true
  
  scope :by_domain, ->(domain) { where(domain: domain) }
  scope :by_category, ->(category) { where(category: category) }
  scope :published, -> { where(published: true) }
  scope :recent, -> { order(created_at: :desc) }
  
  def domain_object
    Domain.find_by(name: domain)
  end
  
  def moderation_status
    content_moderations.last&.status || "pending"
  end
  
  def excerpt(length = 150)
    content.truncate(length, separator: " ")
  end
  
  def reading_time
    words = content.split.size
    (words / 200.0).ceil # Average reading speed: 200 words per minute
  end
end
EOF
  
  # Create domain model
  cat <<EOF > app/models/domain.rb
class Domain < ApplicationRecord
  has_many :blog_posts, foreign_key: :domain, primary_key: :name
  has_many :categories, foreign_key: :domain, primary_key: :name
  has_many :blog_subscriptions, dependent: :destroy
  has_many :analytics_events, foreign_key: :domain, primary_key: :name
  
  validates :name, presence: true, uniqueness: true
  validates :description, presence: true
  
  scope :active, -> { where(active: true) }
  
  def post_count
    blog_posts.count
  end
  
  def subscriber_count
    blog_subscriptions.count
  end
  
  def recent_posts(limit = 5)
    blog_posts.recent.limit(limit)
  end
end
EOF
  
  # Create content moderation job
  mkdir -p app/jobs
  cat <<EOF > app/jobs/content_moderation_job.rb
class ContentModerationJob < ApplicationJob
  queue_as :default
  
  def perform(blog_post)
    # Simulate content moderation (in real implementation, this would use AI/ML)
    moderation_result = moderate_content(blog_post)
    
    ContentModeration.create!(
      blog_post: blog_post,
      status: moderation_result[:status],
      moderator: User.find_by(email: "system@blognet.com") || User.first
    )
    
    # Update blog post status
    blog_post.update!(published: moderation_result[:status] == "approved")
  end
  
  private
  
  def moderate_content(blog_post)
    # Simplified content moderation logic
    content_score = calculate_content_score(blog_post)
    
    if content_score >= 0.8
      { status: "approved", reason: "Content meets quality standards" }
    elsif content_score >= 0.6
      { status: "flagged", reason: "Content requires manual review" }
    else
      { status: "rejected", reason: "Content does not meet quality standards" }
    end
  end
  
  def calculate_content_score(blog_post)
    score = 0.5
    
    # Length check
    score += 0.1 if blog_post.content.length > 200
    
    # Title quality
    score += 0.1 if blog_post.title.length > 10
    
    # Category appropriateness
    score += 0.1 if blog_post.category.present?
    
    # Domain alignment
    score += 0.1 if blog_post.domain.present?
    
    # Basic spam detection
    score -= 0.2 if blog_post.content.downcase.include?("spam")
    score -= 0.2 if blog_post.content.scan(/https?:\/\//).length > 3
    
    [score, 1.0].min
  end
end
EOF
  
  # Create enhanced home controller
  cat <<EOF > app/controllers/home_controller.rb
class HomeController < ApplicationController
  def index
    @cognitive_load = CognitiveLoadMonitor.new
    @complexity_assessment = @cognitive_load.assess_complexity(
      "BlogNet home page with domain showcase and recent posts"
    )
    
    # Cognitive load management: limit to 7 items
    @recent_posts = BlogPost.published.recent.limit(7)
    @active_domains = Domain.active.limit(5)
    @featured_categories = Category.limit(5)
    
    # Flow state tracking
    @flow_tracker = FlowStateTracker.new
    @flow_tracker.update({
      "concentration" => 0.8,
      "challenge_skill_balance" => 0.7,
      "clear_goals" => 0.9
    })
    
    # Analytics tracking
    AnalyticsEvent.create!(
      event_type: "home_page_view",
      domain: "blognet",
      data: { user_id: current_user&.id, timestamp: Time.current }.to_json
    )
  end
end
EOF
  
  # Create seed data for domains
  cat <<EOF > db/seeds.rb
# Create default domains for BlogNet
domains = [
  {
    name: "foodielicio.us",
    description: "Delicious food recipes and culinary experiences",
    active: true
  },
  {
    name: "techblog.net",
    description: "Latest technology news and programming tutorials",
    active: true
  },
  {
    name: "travelogue.com",
    description: "Travel stories and destination guides",
    active: true
  },
  {
    name: "lifestyle.blog",
    description: "Lifestyle tips and personal development",
    active: true
  },
  {
    name: "creative.space",
    description: "Art, design, and creative inspiration",
    active: true
  }
]

domains.each do |domain_attrs|
  Domain.find_or_create_by(name: domain_attrs[:name]) do |domain|
    domain.description = domain_attrs[:description]
    domain.active = domain_attrs[:active]
  end
end

# Create categories for each domain
categories = [
  { name: "Recipes", description: "Food recipes and cooking tips", domain: "foodielicio.us" },
  { name: "Restaurant Reviews", description: "Restaurant reviews and recommendations", domain: "foodielicio.us" },
  { name: "Programming", description: "Programming tutorials and code examples", domain: "techblog.net" },
  { name: "AI & ML", description: "Artificial Intelligence and Machine Learning", domain: "techblog.net" },
  { name: "Destinations", description: "Travel destinations and guides", domain: "travelogue.com" },
  { name: "Tips & Tricks", description: "Travel tips and tricks", domain: "travelogue.com" },
  { name: "Health & Wellness", description: "Health and wellness advice", domain: "lifestyle.blog" },
  { name: "Personal Growth", description: "Personal development content", domain: "lifestyle.blog" },
  { name: "Digital Art", description: "Digital art and design", domain: "creative.space" },
  { name: "Photography", description: "Photography tips and showcases", domain: "creative.space" }
]

categories.each do |category_attrs|
  Category.find_or_create_by(name: category_attrs[:name], domain: category_attrs[:domain]) do |category|
    category.description = category_attrs[:description]
  end
end

puts "✅ BlogNet domains and categories created successfully!"
EOF
  
  # Run seeds
  bin/rails db:seed
  
  log "BlogNet application code generation completed" "INFO"
}

# Override main to use enhanced installation
main() {
  log "Starting BlogNet installation with cognitive framework" "INFO"
  
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
    generate_application_code  # This will use our BlogNet-specific implementation
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
