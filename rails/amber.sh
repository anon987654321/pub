#!/usr/bin/env zsh
# Amber: AI-enhanced fashion network with cognitive framework implementation
# Master.json v10.7.0 compliance with zero-trust security

set -e
setopt extended_glob null_glob

# === COGNITIVE FRAMEWORK CONFIGURATION ===
APP_NAME="amber"
BASE_DIR="/home/dev/rails"
BRGEN_IP="46.23.95.45"

# Source enhanced shared functionality
source "./__shared_enhanced.sh"

# === AMBER-SPECIFIC CONFIGURATION ===
generate_application_code() {
  phase_transition "amber_code_generation" "Creating AI-enhanced fashion network features"
  
  # Generate models with cognitive constraints (7 concepts max)
  bin/rails generate scaffold WardrobeItem name:string description:text category:string photos:attachments user:references
  bin/rails generate scaffold Comment wardrobe_item:references user:references content:text
  bin/rails generate model StyleRecommendation user:references wardrobe_item:references ai_score:decimal
  bin/rails generate model FashionTrend name:string description:text popularity_score:decimal
  bin/rails generate model OutfitCombination title:string description:text user:references
  bin/rails generate model UserPreference user:references style_type:string preference_value:decimal
  bin/rails generate model AiAnalysis wardrobe_item:references analysis_data:text confidence_score:decimal
  
  # Database migrations
  bin/rails db:migrate
  
  # Create cognitive-aware controllers
  cat <<EOF > app/controllers/wardrobe_items_controller.rb
class WardrobeItemsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_wardrobe_item, only: [:show, :edit, :update, :destroy]
  
  def index
    @cognitive_load = CognitiveLoadMonitor.new
    @complexity_assessment = @cognitive_load.assess_complexity(
      "Wardrobe items listing with filtering and search capabilities"
    )
    
    @pagy, @wardrobe_items = pagy(WardrobeItem.all.order(created_at: :desc), items: 7)
  end
  
  def show
    @cognitive_load = CognitiveLoadMonitor.new
    @complexity_assessment = @cognitive_load.assess_complexity(
      "Individual wardrobe item with AI recommendations and styling suggestions"
    )
    
    @ai_analysis = AiAnalysis.find_by(wardrobe_item: @wardrobe_item)
    @recommendations = StyleRecommendation.where(wardrobe_item: @wardrobe_item).limit(5)
  end
  
  def new
    @wardrobe_item = WardrobeItem.new
    @cognitive_load = CognitiveLoadMonitor.new
    @complexity_assessment = @cognitive_load.assess_complexity(
      "Wardrobe item creation form with photo upload and categorization"
    )
  end
  
  def create
    @wardrobe_item = WardrobeItem.new(wardrobe_item_params)
    @wardrobe_item.user = current_user
    
    if @wardrobe_item.save
      # Trigger AI analysis in background
      AiAnalysisJob.perform_later(@wardrobe_item)
      
      respond_to do |format|
        format.html { redirect_to wardrobe_items_path, notice: "Wardrobe item created successfully!" }
        format.turbo_stream
      end
    else
      render :new, status: :unprocessable_entity
    end
  end
  
  def edit
    @cognitive_load = CognitiveLoadMonitor.new
    @complexity_assessment = @cognitive_load.assess_complexity(
      "Wardrobe item editing with validation and photo management"
    )
  end
  
  def update
    if @wardrobe_item.update(wardrobe_item_params)
      respond_to do |format|
        format.html { redirect_to wardrobe_items_path, notice: "Wardrobe item updated successfully!" }
        format.turbo_stream
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end
  
  def destroy
    @wardrobe_item.destroy
    respond_to do |format|
      format.html { redirect_to wardrobe_items_path, notice: "Wardrobe item deleted successfully!" }
      format.turbo_stream
    end
  end
  
  private
  
  def set_wardrobe_item
    @wardrobe_item = WardrobeItem.find(params[:id])
    unless @wardrobe_item.user == current_user || current_user&.admin?
      redirect_to wardrobe_items_path, alert: "Access denied"
    end
  end
  
  def wardrobe_item_params
    params.require(:wardrobe_item).permit(:name, :description, :category, photos: [])
  end
end
EOF
  
  # Create AI recommendation system
  cat <<EOF > app/models/wardrobe_item.rb
class WardrobeItem < ApplicationRecord
  belongs_to :user
  has_many :comments, dependent: :destroy
  has_many :style_recommendations, dependent: :destroy
  has_many :ai_analyses, dependent: :destroy
  has_many_attached :photos
  
  validates :name, presence: true, length: { minimum: 3, maximum: 100 }
  validates :description, presence: true, length: { minimum: 10, maximum: 500 }
  validates :category, presence: true
  
  scope :by_category, ->(category) { where(category: category) }
  scope :recent, -> { order(created_at: :desc) }
  
  def ai_recommendation_score
    ai_analyses.last&.confidence_score || 0.0
  end
  
  def compatible_items
    # AI-based compatibility matching (simplified)
    WardrobeItem.where(user: user)
                .where(category: compatible_categories)
                .where.not(id: id)
                .limit(5)
  end
  
  private
  
  def compatible_categories
    case category.downcase
    when "tops", "shirts"
      ["pants", "skirts", "shorts"]
    when "pants", "jeans"
      ["tops", "shirts", "blouses"]
    when "dresses"
      ["shoes", "accessories"]
    else
      []
    end
  end
end
EOF
  
  # Create AI analysis job
  mkdir -p app/jobs
  cat <<EOF > app/jobs/ai_analysis_job.rb
class AiAnalysisJob < ApplicationJob
  queue_as :default
  
  def perform(wardrobe_item)
    # Simulate AI analysis (in real implementation, this would call external AI service)
    analysis_data = {
      color_analysis: analyze_colors(wardrobe_item),
      style_category: determine_style_category(wardrobe_item),
      versatility_score: calculate_versatility(wardrobe_item),
      season_compatibility: determine_seasons(wardrobe_item),
      recommendations: generate_recommendations(wardrobe_item)
    }
    
    AiAnalysis.create!(
      wardrobe_item: wardrobe_item,
      analysis_data: analysis_data.to_json,
      confidence_score: rand(0.7..0.95) # Simulated confidence
    )
    
    # Generate style recommendations
    generate_style_recommendations(wardrobe_item, analysis_data)
  end
  
  private
  
  def analyze_colors(wardrobe_item)
    # Simplified color analysis
    colors = %w[red blue green yellow black white gray navy burgundy]
    colors.sample(rand(1..3))
  end
  
  def determine_style_category(wardrobe_item)
    styles = %w[casual formal business sporty vintage bohemian minimalist]
    styles.sample
  end
  
  def calculate_versatility(wardrobe_item)
    # Basic versatility calculation
    base_score = 0.5
    base_score += 0.2 if wardrobe_item.category.downcase.in?(%w[jeans shirt])
    base_score += 0.1 if wardrobe_item.description.downcase.include?("versatile")
    base_score += 0.1 if wardrobe_item.description.downcase.include?("classic")
    [base_score, 1.0].min
  end
  
  def determine_seasons(wardrobe_item)
    seasons = %w[spring summer fall winter]
    seasons.sample(rand(1..4))
  end
  
  def generate_recommendations(wardrobe_item)
    [
      "Pairs well with neutral colors",
      "Great for layering",
      "Suitable for both day and evening wear",
      "Consider adding accessories",
      "Perfect for business casual"
    ].sample(rand(2..4))
  end
  
  def generate_style_recommendations(wardrobe_item, analysis_data)
    # Create style recommendations based on AI analysis
    analysis_data[:recommendations].each do |recommendation|
      StyleRecommendation.create!(
        user: wardrobe_item.user,
        wardrobe_item: wardrobe_item,
        ai_score: rand(0.6..0.95)
      )
    end
  end
end
EOF
  
  # Create enhanced home controller
  cat <<EOF > app/controllers/home_controller.rb
class HomeController < ApplicationController
  def index
    @cognitive_load = CognitiveLoadMonitor.new
    @complexity_assessment = @cognitive_load.assess_complexity(
      "Amber home page with AI recommendations, recent items, and fashion trends"
    )
    
    # Limit to 7 items for cognitive load management
    @recent_items = WardrobeItem.recent.limit(7)
    @fashion_trends = FashionTrend.order(popularity_score: :desc).limit(5)
    @ai_recommendations = current_user&.style_recommendations&.limit(3) || []
    
    # Flow state tracking
    @flow_tracker = FlowStateTracker.new
    @flow_tracker.update({
      "concentration" => 0.8,
      "challenge_skill_balance" => 0.7,
      "clear_goals" => 0.9
    })
  end
end
EOF
  
  log "Amber application code generation completed" "INFO"
}

# Override main to use enhanced installation
main() {
  log "Starting Amber installation with cognitive framework" "INFO"
  
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
    generate_application_code  # This will use our Amber-specific implementation
    setup_testing
    finalize_installation
  else
    # Fallback to original installation
    setup_full_app "$APP_NAME"
  fi
}

bin/rails generate scaffold WardrobeItem name:string description:text user:references category:string photos:attachments
bin/rails generate scaffold Comment wardrobe_item:references user:references content:text

cat <<EOF > app/reflexes/wardrobe_items_infinite_scroll_reflex.rb
class WardrobeItemsInfiniteScrollReflex < InfiniteScrollReflex
  def load_more
    @pagy, @collection = pagy(WardrobeItem.all.order(created_at: :desc), page: page)
    super
  end
end
EOF

cat <<EOF > app/reflexes/comments_infinite_scroll_reflex.rb
class CommentsInfiniteScrollReflex < InfiniteScrollReflex
  def load_more
    @pagy, @collection = pagy(Comment.all.order(created_at: :desc), page: page)
    super
  end
end
EOF

cat <<EOF > app/reflexes/ai_recommendation_reflex.rb
class AiRecommendationReflex < ApplicationReflex
  def recommend
    items = WardrobeItem.all
    recommendations = items.sample(3).map(&:name).join(", ")
    cable_ready.replace(selector: "#ai-recommendations", html: "<div class='recommendations'>Recommended: #{recommendations}</div>").broadcast
  end
end
EOF

cat <<EOF > app/javascript/controllers/ai_recommendation_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["output"]

  recommend(event) {
    event.preventDefault()
    if (!this.hasOutputTarget) {
      console.error("AiRecommendationController: Output target not found")
      return
    }
    this.outputTarget.innerHTML = "<i class='fas fa-spinner fa-spin' aria-label='<%= t('amber.recommending') %>'></i>"
    this.stimulate("AiRecommendationReflex#recommend")
  }
}
EOF

cat <<EOF > app/controllers/wardrobe_items_controller.rb
class WardrobeItemsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_wardrobe_item, only: [:show, :edit, :update, :destroy]

  def index
    @pagy, @wardrobe_items = pagy(WardrobeItem.all.order(created_at: :desc)) unless @stimulus_reflex
  end

  def show
  end

  def new
    @wardrobe_item = WardrobeItem.new
  end

  def create
    @wardrobe_item = WardrobeItem.new(wardrobe_item_params)
    @wardrobe_item.user = current_user
    if @wardrobe_item.save
      respond_to do |format|
        format.html { redirect_to wardrobe_items_path, notice: t("amber.wardrobe_item_created") }
        format.turbo_stream
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @wardrobe_item.update(wardrobe_item_params)
      respond_to do |format|
        format.html { redirect_to wardrobe_items_path, notice: t("amber.wardrobe_item_updated") }
        format.turbo_stream
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @wardrobe_item.destroy
    respond_to do |format|
      format.html { redirect_to wardrobe_items_path, notice: t("amber.wardrobe_item_deleted") }
      format.turbo_stream
    end
  end

  private

  def set_wardrobe_item
    @wardrobe_item = WardrobeItem.find(params[:id])
    redirect_to wardrobe_items_path, alert: t("amber.not_authorized") unless @wardrobe_item.user == current_user || current_user&.admin?
  end

  def wardrobe_item_params
    params.require(:wardrobe_item).permit(:name, :description, :category, photos: [])
  end
end
EOF

cat <<EOF > app/controllers/comments_controller.rb
class CommentsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_comment, only: [:show, :edit, :update, :destroy]

  def index
    @pagy, @comments = pagy(Comment.all.order(created_at: :desc)) unless @stimulus_reflex
  end

  def show
  end

  def new
    @comment = Comment.new
  end

  def create
    @comment = Comment.new(comment_params)
    @comment.user = current_user
    if @comment.save
      respond_to do |format|
        format.html { redirect_to comments_path, notice: t("amber.comment_created") }
        format.turbo_stream
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @comment.update(comment_params)
      respond_to do |format|
        format.html { redirect_to comments_path, notice: t("amber.comment_updated") }
        format.turbo_stream
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @comment.destroy
    respond_to do |format|
      format.html { redirect_to comments_path, notice: t("amber.comment_deleted") }
      format.turbo_stream
    end
  end

  private

  def set_comment
    @comment = Comment.find(params[:id])
    redirect_to comments_path, alert: t("amber.not_authorized") unless @comment.user == current_user || current_user&.admin?
  end

  def comment_params
    params.require(:comment).permit(:wardrobe_item_id, :content)
  end
end
EOF

cat <<EOF > app/controllers/home_controller.rb
class HomeController < ApplicationController
  def index
    @pagy, @posts = pagy(Post.all.order(created_at: :desc), items: 10) unless @stimulus_reflex
    @wardrobe_items = WardrobeItem.all.order(created_at: :desc).limit(5)
  end
end
EOF

mkdir -p app/views/amber_logo

cat <<EOF > app/views/amber_logo/_logo.html.erb
<%= tag.svg xmlns: "http://www.w3.org/2000/svg", viewBox: "0 0 100 50", role: "img", class: "logo", "aria-label": t("amber.logo_alt") do %>
  <%= tag.title t("amber.logo_title", default: "Amber Logo") %>
  <%= tag.text x: "50", y: "30", "text-anchor": "middle", "font-family": "Helvetica, Arial, sans-serif", "font-size": "16", fill: "#f44336" do %>Amber<% end %>
<% end %>
EOF

cat <<EOF > app/views/shared/_header.html.erb
<%= tag.header role: "banner" do %>
  <%= render partial: "amber_logo/logo" %>
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
<% content_for :title, t("amber.home_title") %>
<% content_for :description, t("amber.home_description") %>
<% content_for :keywords, t("amber.home_keywords", default: "amber, fashion, ai recommendations") %>
<% content_for :schema do %>
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "WebPage",
    "name": "<%= t('amber.home_title') %>",
    "description": "<%= t('amber.home_description') %>",
    "url": "<%= request.original_url %>",
    "publisher": {
      "@type": "Organization",
      "name": "Amber",
      "logo": {
        "@type": "ImageObject",
        "url": "<%= image_url('amber_logo.svg') %>"
      }
    }
  }
  </script>
<% end %>
<%= render "shared/header" %>
<%= tag.main role: "main" do %>
  <%= tag.section aria-labelledby: "post-heading" do %>
    <%= tag.h1 t("amber.post_title"), id: "post-heading" %>
    <%= tag.div data: { turbo_frame: "notices" } do %>
      <%= render "shared/notices" %>
    <% end %>
    <%= render partial: "posts/form", locals: { post: Post.new } %>
  <% end %>
  <%= render partial: "shared/search", locals: { model: "WardrobeItem", field: "name" } %>
  <%= tag.section aria-labelledby: "wardrobe-items-heading" do %>
    <%= tag.h2 t("amber.wardrobe_items_title"), id: "wardrobe-items-heading" %>
    <%= link_to t("amber.new_wardrobe_item"), new_wardrobe_item_path, class: "button", "aria-label": t("amber.new_wardrobe_item") if current_user %>
    <%= turbo_frame_tag "wardrobe_items" data: { controller: "infinite-scroll" } do %>
      <% @wardrobe_items.each do |wardrobe_item| %>
        <%= render partial: "wardrobe_items/card", locals: { wardrobe_item: wardrobe_item } %>
      <% end %>
      <%= tag.div id: "sentinel", class: "hidden", data: { reflex: "WardrobeItemsInfiniteScroll#load_more", next_page: @pagy.next || 2 } %>
    <% end %>
    <%= tag.button t("amber.load_more"), id: "load-more", data: { reflex: "click->WardrobeItemsInfiniteScroll#load_more", "next-page": @pagy.next || 2, "reflex-root": "#load-more" }, class: @pagy&.next ? "" : "hidden", "aria-label": t("amber.load_more") %>
  <% end %>
  <%= tag.section aria-labelledby: "posts-heading" do %>
    <%= tag.h2 t("amber.posts_title"), id: "posts-heading" %>
    <%= turbo_frame_tag "posts" data: { controller: "infinite-scroll" } do %>
      <% @posts.each do |post| %>
        <%= render partial: "posts/card", locals: { post: post } %>
      <% end %>
      <%= tag.div id: "sentinel", class: "hidden", data: { reflex: "PostsInfiniteScroll#load_more", next_page: @pagy.next || 2 } %>
    <% end %>
    <%= tag.button t("amber.load_more"), id: "load-more", data: { reflex: "click->PostsInfiniteScroll#load_more", "next-page": @pagy.next || 2, "reflex-root": "#load-more" }, class: @pagy&.next ? "" : "hidden", "aria-label": t("amber.load_more") %>
  <% end %>
  <%= tag.section aria-labelledby: "ai-recommendations-heading" do %>
    <%= tag.h2 t("amber.ai_recommendations_title"), id: "ai-recommendations-heading" %>
    <%= tag.div data: { controller: "ai-recommendation" } do %>
      <%= tag.button t("amber.get_recommendations"), data: { action: "click->ai-recommendation#recommend" }, "aria-label": t("amber.get_recommendations") %>
      <%= tag.div id: "ai-recommendations", data: { "ai-recommendation-target": "output" } %>
    <% end %>
  <% end %>
  <%= render partial: "shared/chat" %>
<% end %>
<%= render "shared/footer" %>
EOF

cat <<EOF > app/views/wardrobe_items/index.html.erb
<% content_for :title, t("amber.wardrobe_items_title") %>
<% content_for :description, t("amber.wardrobe_items_description") %>
<% content_for :keywords, t("amber.wardrobe_items_keywords", default: "amber, wardrobe items, fashion") %>
<% content_for :schema do %>
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "WebPage",
    "name": "<%= t('amber.wardrobe_items_title') %>",
    "description": "<%= t('amber.wardrobe_items_description') %>",
    "url": "<%= request.original_url %>",
    "hasPart": [
      <% @wardrobe_items.each do |wardrobe_item| %>
      {
        "@type": "Product",
        "name": "<%= wardrobe_item.name %>",
        "description": "<%= wardrobe_item.description&.truncate(160) %>",
        "category": "<%= wardrobe_item.category %>"
      }<%= "," unless wardrobe_item == @wardrobe_items.last %>
      <% end %>
    ]
  }
  </script>
<% end %>
<%= render "shared/header" %>
<%= tag.main role: "main" do %>
  <%= tag.section aria-labelledby: "wardrobe-items-heading" do %>
    <%= tag.h1 t("amber.wardrobe_items_title"), id: "wardrobe-items-heading" %>
    <%= tag.div data: { turbo_frame: "notices" } do %>
      <%= render "shared/notices" %>
    <% end %>
    <%= link_to t("amber.new_wardrobe_item"), new_wardrobe_item_path, class: "button", "aria-label": t("amber.new_wardrobe_item") if current_user %>
    <%= turbo_frame_tag "wardrobe_items" data: { controller: "infinite-scroll" } do %>
      <% @wardrobe_items.each do |wardrobe_item| %>
        <%= render partial: "wardrobe_items/card", locals: { wardrobe_item: wardrobe_item } %>
      <% end %>
      <%= tag.div id: "sentinel", class: "hidden", data: { reflex: "WardrobeItemsInfiniteScroll#load_more", next_page: @pagy.next || 2 } %>
    <% end %>
    <%= tag.button t("amber.load_more"), id: "load-more", data: { reflex: "click->WardrobeItemsInfiniteScroll#load_more", "next-page": @pagy.next || 2, "reflex-root": "#load-more" }, class: @pagy&.next ? "" : "hidden", "aria-label": t("amber.load_more") %>
  <% end %>
  <%= render partial: "shared/search", locals: { model: "WardrobeItem", field: "name" } %>
<% end %>
<%= render "shared/footer" %>
EOF

cat <<EOF > app/views/wardrobe_items/_card.html.erb
<%= turbo_frame_tag dom_id(wardrobe_item) do %>
  <%= tag.article class: "post-card", id: dom_id(wardrobe_item), role: "article" do %>
    <%= tag.div class: "post-header" do %>
      <%= tag.span t("amber.posted_by", user: wardrobe_item.user.email) %>
      <%= tag.span wardrobe_item.created_at.strftime("%Y-%m-%d %H:%M") %>
    <% end %>
    <%= tag.h2 wardrobe_item.name %>
    <%= tag.p wardrobe_item.description %>
    <%= tag.p t("amber.wardrobe_item_category", category: wardrobe_item.category) %>
    <% if wardrobe_item.photos.attached? %>
      <% wardrobe_item.photos.each do |photo| %>
        <%= image_tag photo, style: "max-width: 200px;", alt: t("amber.wardrobe_item_photo", name: wardrobe_item.name) %>
      <% end %>
    <% end %>
    <%= render partial: "shared/vote", locals: { votable: wardrobe_item } %>
    <%= tag.p class: "post-actions" do %>
      <%= link_to t("amber.view_wardrobe_item"), wardrobe_item_path(wardrobe_item), "aria-label": t("amber.view_wardrobe_item") %>
      <%= link_to t("amber.edit_wardrobe_item"), edit_wardrobe_item_path(wardrobe_item), "aria-label": t("amber.edit_wardrobe_item") if wardrobe_item.user == current_user || current_user&.admin? %>
      <%= button_to t("amber.delete_wardrobe_item"), wardrobe_item_path(wardrobe_item), method: :delete, data: { turbo_confirm: t("amber.confirm_delete") }, form: { data: { turbo_frame: "_top" } }, "aria-label": t("amber.delete_wardrobe_item") if wardrobe_item.user == current_user || current_user&.admin? %>
    <% end %>
  <% end %>
<% end %>
EOF

cat <<EOF > app/views/wardrobe_items/_form.html.erb
<%= form_with model: wardrobe_item, local: true, data: { controller: "character-counter form-validation", turbo: true } do |form| %>
  <%= tag.div data: { turbo_frame: "notices" } do %>
    <%= render "shared/notices" %>
  <% end %>
  <% if wardrobe_item.errors.any? %>
    <%= tag.div role: "alert" do %>
      <%= tag.p t("amber.errors", count: wardrobe_item.errors.count) %>
      <%= tag.ul do %>
        <% wardrobe_item.errors.full_messages.each do |msg| %>
          <%= tag.li msg %>
        <% end %>
      <% end %>
    <% end %>
  <% end %>
  <%= tag.fieldset do %>
    <%= form.label :name, t("amber.wardrobe_item_name"), "aria-required": true %>
    <%= form.text_field :name, required: true, data: { "form-validation-target": "input", action: "input->form-validation#validate" }, title: t("amber.wardrobe_item_name_help") %>
    <%= tag.span class: "error-message" data: { "form-validation-target": "error", for: "wardrobe_item_name" } %>
  <% end %>
  <%= tag.fieldset do %>
    <%= form.label :description, t("amber.wardrobe_item_description"), "aria-required": true %>
    <%= form.text_area :description, required: true, data: { "character-counter-target": "input", "textarea-autogrow-target": "input", "form-validation-target": "input", action: "input->character-counter#count input->textarea-autogrow#resize input->form-validation#validate" }, title: t("amber.wardrobe_item_description_help") %>
    <%= tag.span data: { "character-counter-target": "count" } %>
    <%= tag.span class: "error-message" data: { "form-validation-target": "error", for: "wardrobe_item_description" } %>
  <% end %>
  <%= tag.fieldset do %>
    <%= form.label :category, t("amber.wardrobe_item_category"), "aria-required": true %>
    <%= form.text_field :category, required: true, data: { "form-validation-target": "input", action: "input->form-validation#validate" }, title: t("amber.wardrobe_item_category_help") %>
    <%= tag.span class: "error-message" data: { "form-validation-target": "error", for: "wardrobe_item_category" } %>
  <% end %>
  <%= tag.fieldset do %>
    <%= form.label :photos, t("amber.wardrobe_item_photos"), "aria-required": true %>
    <%= form.file_field :photos, multiple: true, accept: "image/*", required: !wardrobe_item.persisted?, data: { controller: "file-preview", "file-preview-target": "input" } %>
    <% if wardrobe_item.photos.attached? %>
      <% wardrobe_item.photos.each do |photo| %>
        <%= image_tag photo, style: "max-width: 200px;", alt: t("amber.wardrobe_item_photo", name: wardrobe_item.name) %>
      <% end %>
    <% end %>
    <%= tag.div data: { "file-preview-target": "preview" }, style: "display: none;" %>
  <% end %>
  <%= form.submit t("amber.#{wardrobe_item.persisted? ? 'update' : 'create'}_wardrobe_item"), data: { turbo_submits_with: t("amber.#{wardrobe_item.persisted? ? 'updating' : 'creating'}_wardrobe_item") } %>
<% end %>
EOF

cat <<EOF > app/views/wardrobe_items/new.html.erb
<% content_for :title, t("amber.new_wardrobe_item_title") %>
<% content_for :description, t("amber.new_wardrobe_item_description") %>
<% content_for :keywords, t("amber.new_wardrobe_item_keywords", default: "add wardrobe item, amber, fashion") %>
<% content_for :schema do %>
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "WebPage",
    "name": "<%= t('amber.new_wardrobe_item_title') %>",
    "description": "<%= t('amber.new_wardrobe_item_description') %>",
    "url": "<%= request.original_url %>"
  }
  </script>
<% end %>
<%= render "shared/header" %>
<%= tag.main role: "main" do %>
  <%= tag.section aria-labelledby: "new-wardrobe-item-heading" do %>
    <%= tag.h1 t("amber.new_wardrobe_item_title"), id: "new-wardrobe-item-heading" %>
    <%= render partial: "wardrobe_items/form", locals: { wardrobe_item: @wardrobe_item } %>
  <% end %>
<% end %>
<%= render "shared/footer" %>
EOF

cat <<EOF > app/views/wardrobe_items/edit.html.erb
<% content_for :title, t("amber.edit_wardrobe_item_title") %>
<% content_for :description, t("amber.edit_wardrobe_item_description") %>
<% content_for :keywords, t("amber.edit_wardrobe_item_keywords", default: "edit wardrobe item, amber, fashion") %>
<% content_for :schema do %>
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "WebPage",
    "name": "<%= t('amber.edit_wardrobe_item_title') %>",
    "description": "<%= t('amber.edit_wardrobe_item_description') %>",
    "url": "<%= request.original_url %>"
  }
  </script>
<% end %>
<%= render "shared/header" %>
<%= tag.main role: "main" do %>
  <%= tag.section aria-labelledby: "edit-wardrobe-item-heading" do %>
    <%= tag.h1 t("amber.edit_wardrobe_item_title"), id: "edit-wardrobe-item-heading" %>
    <%= render partial: "wardrobe_items/form", locals: { wardrobe_item: @wardrobe_item } %>
  <% end %>
<% end %>
<%= render "shared/footer" %>
EOF

cat <<EOF > app/views/wardrobe_items/show.html.erb
<% content_for :title, @wardrobe_item.name %>
<% content_for :description, @wardrobe_item.description&.truncate(160) %>
<% content_for :keywords, t("amber.wardrobe_item_keywords", name: @wardrobe_item.name, default: "wardrobe item, #{@wardrobe_item.name}, amber, fashion") %>
<% content_for :schema do %>
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "Product",
    "name": "<%= @wardrobe_item.name %>",
    "description": "<%= @wardrobe_item.description&.truncate(160) %>",
    "category": "<%= @wardrobe_item.category %>"
  }
  </script>
<% end %>
<%= render "shared/header" %>
<%= tag.main role: "main" do %>
  <%= tag.section aria-labelledby: "wardrobe-item-heading" class: "post-card" do %>
    <%= tag.div data: { turbo_frame: "notices" } do %>
      <%= render "shared/notices" %>
    <% end %>
    <%= tag.h1 @wardrobe_item.name, id: "wardrobe-item-heading" %>
    <%= render partial: "wardrobe_items/card", locals: { wardrobe_item: @wardrobe_item } %>
  <% end %>
<% end %>
<%= render "shared/footer" %>
EOF

cat <<EOF > app/views/comments/index.html.erb
<% content_for :title, t("amber.comments_title") %>
<% content_for :description, t("amber.comments_description") %>
<% content_for :keywords, t("amber.comments_keywords", default: "amber, comments, fashion") %>
<% content_for :schema do %>
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "WebPage",
    "name": "<%= t('amber.comments_title') %>",
    "description": "<%= t('amber.comments_description') %>",
    "url": "<%= request.original_url %>"
  }
  </script>
<% end %>
<%= render "shared/header" %>
<%= tag.main role: "main" do %>
  <%= tag.section aria-labelledby: "comments-heading" do %>
    <%= tag.h1 t("amber.comments_title"), id: "comments-heading" %>
    <%= tag.div data: { turbo_frame: "notices" } do %>
      <%= render "shared/notices" %>
    <% end %>
    <%= link_to t("amber.new_comment"), new_comment_path, class: "button", "aria-label": t("amber.new_comment") %>
    <%= turbo_frame_tag "comments" data: { controller: "infinite-scroll" } do %>
      <% @comments.each do |comment| %>
        <%= render partial: "comments/card", locals: { comment: comment } %>
      <% end %>
      <%= tag.div id: "sentinel", class: "hidden", data: { reflex: "CommentsInfiniteScroll#load_more", next_page: @pagy.next || 2 } %>
    <% end %>
    <%= tag.button t("amber.load_more"), id: "load-more", data: { reflex: "click->CommentsInfiniteScroll#load_more", "next-page": @pagy.next || 2, "reflex-root": "#load-more" }, class: @pagy&.next ? "" : "hidden", "aria-label": t("amber.load_more") %>
  <% end %>
<% end %>
<%= render "shared/footer" %>
EOF

cat <<EOF > app/views/comments/_card.html.erb
<%= turbo_frame_tag dom_id(comment) do %>
  <%= tag.article class: "post-card", id: dom_id(comment), role: "article" do %>
    <%= tag.div class: "post-header" do %>
      <%= tag.span t("amber.posted_by", user: comment.user.email) %>
      <%= tag.span comment.created_at.strftime("%Y-%m-%d %H:%M") %>
    <% end %>
    <%= tag.h2 comment.wardrobe_item.name %>
    <%= tag.p comment.content %>
    <%= render partial: "shared/vote", locals: { votable: comment } %>
    <%= tag.p class: "post-actions" do %>
      <%= link_to t("amber.view_comment"), comment_path(comment), "aria-label": t("amber.view_comment") %>
      <%= link_to t("amber.edit_comment"), edit_comment_path(comment), "aria-label": t("amber.edit_comment") if comment.user == current_user || current_user&.admin? %>
      <%= button_to t("amber.delete_comment"), comment_path(comment), method: :delete, data: { turbo_confirm: t("amber.confirm_delete") }, form: { data: { turbo_frame: "_top" } }, "aria-label": t("amber.delete_comment") if comment.user == current_user || current_user&.admin? %>
    <% end %>
  <% end %>
<% end %>
EOF

cat <<EOF > app/views/comments/_form.html.erb
<%= form_with model: comment, local: true, data: { controller: "character-counter form-validation", turbo: true } do |form| %>
  <%= tag.div data: { turbo_frame: "notices" } do %>
    <%= render "shared/notices" %>
  <% end %>
  <% if comment.errors.any? %>
    <%= tag.div role: "alert" do %>
      <%= tag.p t("amber.errors", count: comment.errors.count) %>
      <%= tag.ul do %>
        <% comment.errors.full_messages.each do |msg| %>
          <%= tag.li msg %>
        <% end %>
      <% end %>
    <% end %>
  <% end %>
  <%= tag.fieldset do %>
    <%= form.label :wardrobe_item_id, t("amber.comment_wardrobe_item"), "aria-required": true %>
    <%= form.collection_select :wardrobe_item_id, WardrobeItem.all, :id, :name, { prompt: t("amber.wardrobe_item_prompt") }, required: true %>
    <%= tag.span class: "error-message" data: { "form-validation-target": "error", for: "comment_wardrobe_item_id" } %>
  <% end %>
  <%= tag.fieldset do %>
    <%= form.label :content, t("amber.comment_content"), "aria-required": true %>
    <%= form.text_area :content, required: true, data: { "character-counter-target": "input", "textarea-autogrow-target": "input", "form-validation-target": "input", action: "input->character-counter#count input->textarea-autogrow#resize input->form-validation#validate" }, title: t("amber.comment_content_help") %>
    <%= tag.span data: { "character-counter-target": "count" } %>
    <%= tag.span class: "error-message" data: { "form-validation-target": "error", for: "comment_content" } %>
  <% end %>
  <%= form.submit t("amber.#{comment.persisted? ? 'update' : 'create'}_comment"), data: { turbo_submits_with: t("amber.#{comment.persisted? ? 'updating' : 'creating'}_comment") } %>
<% end %>
EOF

cat <<EOF > app/views/comments/new.html.erb
<% content_for :title, t("amber.new_comment_title") %>
<% content_for :description, t("amber.new_comment_description") %>
<% content_for :keywords, t("amber.new_comment_keywords", default: "add comment, amber, fashion") %>
<% content_for :schema do %>
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "WebPage",
    "name": "<%= t('amber.new_comment_title') %>",
    "description": "<%= t('amber.new_comment_description') %>",
    "url": "<%= request.original_url %>"
  }
  </script>
<% end %>
<%= render "shared/header" %>
<%= tag.main role: "main" do %>
  <%= tag.section aria-labelledby: "new-comment-heading" do %>
    <%= tag.h1 t("amber.new_comment_title"), id: "new-comment-heading" %>
    <%= render partial: "comments/form", locals: { comment: @comment } %>
  <% end %>
<% end %>
<%= render "shared/footer" %>
EOF

cat <<EOF > app/views/comments/edit.html.erb
<% content_for :title, t("amber.edit_comment_title") %>
<% content_for :description, t("amber.edit_comment_description") %>
<% content_for :keywords, t("amber.edit_comment_keywords", default: "edit comment, amber, fashion") %>
<% content_for :schema do %>
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "WebPage",
    "name": "<%= t('amber.edit_comment_title') %>",
    "description": "<%= t('amber.edit_comment_description') %>",
    "url": "<%= request.original_url %>"
  }
  </script>
<% end %>
<%= render "shared/header" %>
<%= tag.main role: "main" do %>
  <%= tag.section aria-labelledby: "edit-comment-heading" do %>
    <%= tag.h1 t("amber.edit_comment_title"), id: "edit-comment-heading" %>
    <%= render partial: "comments/form", locals: { comment: @comment } %>
  <% end %>
<% end %>
<%= render "shared/footer" %>
EOF

cat <<EOF > app/views/comments/show.html.erb
<% content_for :title, t("amber.comment_title", wardrobe_item: @comment.wardrobe_item.name) %>
<% content_for :description, @comment.content&.truncate(160) %>
<% content_for :keywords, t("amber.comment_keywords", wardrobe_item: @comment.wardrobe_item.name, default: "comment, #{@comment.wardrobe_item.name}, amber, fashion") %>
<% content_for :schema do %>
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "Comment",
    "text": "<%= @comment.content&.truncate(160) %>",
    "about": {
      "@type": "Product",
      "name": "<%= @comment.wardrobe_item.name %>"
    }
  }
  </script>
<% end %>
<%= render "shared/header" %>
<%= tag.main role: "main" do %>
  <%= tag.section aria-labelledby: "comment-heading" class: "post-card" do %>
    <%= tag.div data: { turbo_frame: "notices" } do %>
      <%= render "shared/notices" %>
    <% end %>
    <%= tag.h1 t("amber.comment_title", wardrobe_item: @comment.wardrobe_item.name), id: "comment-heading" %>
    <%= render partial: "comments/card", locals: { comment: @comment } %>
  <% end %>
<% end %>
<%= render "shared/footer" %>
EOF

generate_turbo_views "wardrobe_items" "wardrobe_item"
generate_turbo_views "comments" "comment"

commit "Amber setup complete: AI-enhanced fashion network with live search and anonymous features"

log "Amber setup complete. Run 'bin/falcon-host' with PORT set to start on OpenBSD."

# Change Log:
# - Aligned with master.json v6.5.0: Two-space indents, double quotes, heredocs, Strunk & White comments.
# - Used Rails 8 conventions, Hotwire, Turbo Streams, Stimulus Reflex, I18n, and Falcon.
# - Leveraged bin/rails generate scaffold for WardrobeItems and Comments to streamline CRUD setup.
# - Extracted header, footer, search, and model-specific forms/cards into partials for DRY views.
# - Added AI recommendation reflex and controller for fashion suggestions.
# - Included live search, infinite scroll, and anonymous posting/chat via shared utilities.
# - Ensured NNG principles, SEO, schema data, and minimal flat design compliance.
# - Finalized for unprivileged user on OpenBSD 7.5.