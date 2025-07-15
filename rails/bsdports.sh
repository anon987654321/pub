#!/usr/bin/env zsh
# BSDPorts: OpenBSD package management platform with cognitive framework implementation
# Master.json v10.7.0 compliance with zero-trust security

set -e
setopt extended_glob null_glob

# === COGNITIVE FRAMEWORK CONFIGURATION ===
APP_NAME="bsdports"
BASE_DIR="/home/dev/rails"
BRGEN_IP="46.23.95.45"

# Source enhanced shared functionality
source "./__shared_enhanced.sh"

# === BSDPORTS-SPECIFIC CONFIGURATION ===
generate_application_code() {
  phase_transition "bsdports_code_generation" "Creating OpenBSD package management platform features"
  
  # Generate models with cognitive constraints (7 concepts max)
  bin/rails generate model Package name:string version:string description:text user:references category:string maintainer:string
  bin/rails generate model PackageDependency package:references depends_on:references dependency_type:string
  bin/rails generate model BuildLog package:references build_status:string log_content:text build_time:integer
  bin/rails generate model PackageReview user:references package:references rating:integer content:text
  bin/rails generate model SecurityAlert package:references severity:string description:text fixed_in_version:string
  bin/rails generate model PortsTree name:string description:text last_updated:datetime active:boolean
  bin/rails generate model PackageStatistics package:references download_count:integer build_success_rate:decimal
  
  # Database migrations
  bin/rails db:migrate
  
  # Install additional gems for BSDPorts
  cat <<EOF >> Gemfile

# BSDPorts-specific gems
gem "rugged", "~> 1.6"
gem "semantic", "~> 1.6"
gem "ruby-progressbar", "~> 1.13"
gem "net-ssh", "~> 7.0"
gem "net-scp", "~> 4.0"
gem "nokogiri", "~> 1.15"
gem "chronic", "~> 0.10"
EOF
  
  bundle install
  
  # Create cognitive-aware controllers
  cat <<EOF > app/controllers/packages_controller.rb
class PackagesController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_package, only: [:show, :edit, :update, :destroy, :build, :dependencies]
  before_action :check_maintainer_permissions, only: [:edit, :update, :destroy]
  
  def index
    @cognitive_load = CognitiveLoadMonitor.new
    @complexity_assessment = @cognitive_load.assess_complexity(
      "Package listing with dependency tracking and build status management"
    )
    
    # Cognitive load management: limit to 7 packages
    @pagy, @packages = pagy(filtered_packages.order(updated_at: :desc), items: 7)
    @categories = Package.distinct.pluck(:category).compact.sort
    @recent_builds = BuildLog.order(created_at: :desc).limit(5)
  end
  
  def show
    @cognitive_load = CognitiveLoadMonitor.new
    @complexity_assessment = @cognitive_load.assess_complexity(
      "Package details with dependencies, build logs, and security alerts"
    )
    
    @dependencies = @package.package_dependencies
                            .includes(:depends_on)
                            .order(:dependency_type)
                            .limit(10)
    
    @build_logs = @package.build_logs
                          .order(created_at: :desc)
                          .limit(5)
    
    @security_alerts = @package.security_alerts
                               .order(created_at: :desc)
                               .limit(3)
    
    @reviews = @package.package_reviews
                       .includes(:user)
                       .order(created_at: :desc)
                       .limit(5)
    
    @statistics = @package.package_statistics.first
  end
  
  def new
    @package = Package.new
    @cognitive_load = CognitiveLoadMonitor.new
    @complexity_assessment = @cognitive_load.assess_complexity(
      "Package creation with dependency management and build configuration"
    )
    
    @categories = Package.distinct.pluck(:category).compact.sort
    @available_dependencies = Package.order(:name).limit(100)
  end
  
  def create
    @package = Package.new(package_params)
    @package.user = current_user
    @package.maintainer = current_user.email
    
    if @package.save
      # Initialize package statistics
      @package.create_package_statistics!(
        download_count: 0,
        build_success_rate: 0.0
      )
      
      # Queue initial build
      PackageBuildJob.perform_later(@package)
      
      respond_to do |format|
        format.html { redirect_to @package, notice: "Package created successfully!" }
        format.turbo_stream
      end
    else
      @categories = Package.distinct.pluck(:category).compact.sort
      @available_dependencies = Package.order(:name).limit(100)
      render :new, status: :unprocessable_entity
    end
  end
  
  def edit
    @cognitive_load = CognitiveLoadMonitor.new
    @complexity_assessment = @cognitive_load.assess_complexity(
      "Package editing with dependency updates and version management"
    )
    
    @categories = Package.distinct.pluck(:category).compact.sort
    @available_dependencies = Package.where.not(id: @package.id).order(:name).limit(100)
  end
  
  def update
    if @package.update(package_params)
      # Queue rebuild if version changed
      if @package.saved_change_to_version?
        PackageBuildJob.perform_later(@package)
      end
      
      respond_to do |format|
        format.html { redirect_to @package, notice: "Package updated successfully!" }
        format.turbo_stream
      end
    else
      @categories = Package.distinct.pluck(:category).compact.sort
      @available_dependencies = Package.where.not(id: @package.id).order(:name).limit(100)
      render :edit, status: :unprocessable_entity
    end
  end
  
  def destroy
    @package.destroy
    respond_to do |format|
      format.html { redirect_to packages_path, notice: "Package deleted successfully!" }
      format.turbo_stream
    end
  end
  
  def build
    # Manual build trigger
    PackageBuildJob.perform_later(@package)
    
    respond_to do |format|
      format.html { redirect_to @package, notice: "Build queued successfully!" }
      format.json { render json: { status: "queued" } }
    end
  end
  
  def dependencies
    @dependencies = @package.package_dependencies
                            .includes(:depends_on)
                            .order(:dependency_type)
    
    respond_to do |format|
      format.html
      format.json { render json: @dependencies }
    end
  end
  
  private
  
  def set_package
    @package = Package.find(params[:id])
  end
  
  def package_params
    params.require(:package).permit(:name, :version, :description, :category, :maintainer)
  end
  
  def filtered_packages
    packages = Package.all
    packages = packages.where(category: params[:category]) if params[:category].present?
    packages = packages.where("name ILIKE ? OR description ILIKE ?", "%#{params[:search]}%", "%#{params[:search]}%") if params[:search].present?
    packages = packages.where("version = ?", params[:version]) if params[:version].present?
    packages
  end
  
  def check_maintainer_permissions
    unless @package.user == current_user || current_user&.admin?
      redirect_to @package, alert: "Only package maintainers can edit this package"
    end
  end
end
EOF
  
  # Create package model with dependency management
  cat <<EOF > app/models/package.rb
class Package < ApplicationRecord
  belongs_to :user
  has_many :package_dependencies, dependent: :destroy
  has_many :depends_on, through: :package_dependencies, source: :depends_on
  has_many :reverse_dependencies, class_name: "PackageDependency", foreign_key: "depends_on_id"
  has_many :build_logs, dependent: :destroy
  has_many :package_reviews, dependent: :destroy
  has_many :security_alerts, dependent: :destroy
  has_one :package_statistics, dependent: :destroy
  
  validates :name, presence: true, uniqueness: { scope: :version }, length: { minimum: 2, maximum: 100 }
  validates :version, presence: true, format: { with: /\A\d+\.\d+(\.\d+)?(-\w+)?\z/ }
  validates :description, presence: true, length: { minimum: 10, maximum: 1000 }
  validates :category, presence: true
  validates :maintainer, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  
  scope :by_category, ->(category) { where(category: category) }
  scope :by_maintainer, ->(maintainer) { where(maintainer: maintainer) }
  scope :recent, -> { order(updated_at: :desc) }
  scope :popular, -> { joins(:package_statistics).order("package_statistics.download_count DESC") }
  
  def latest_build
    build_logs.order(created_at: :desc).first
  end
  
  def build_status
    latest_build&.build_status || "unknown"
  end
  
  def build_success_rate
    return 0.0 if build_logs.empty?
    
    successful_builds = build_logs.where(build_status: "success").count
    total_builds = build_logs.count
    
    (successful_builds.to_f / total_builds * 100).round(2)
  end
  
  def has_security_alerts?
    security_alerts.any?
  end
  
  def critical_security_alerts
    security_alerts.where(severity: "critical")
  end
  
  def dependency_tree
    # Build dependency tree (simplified)
    dependencies = package_dependencies.includes(:depends_on)
    dependencies.map do |dep|
      {
        name: dep.depends_on.name,
        version: dep.depends_on.version,
        type: dep.dependency_type,
        recursive: dep.depends_on.dependency_tree
      }
    end
  end
  
  def reverse_dependency_count
    reverse_dependencies.count
  end
  
  def average_rating
    package_reviews.average(:rating) || 0.0
  end
  
  def download_count
    package_statistics&.download_count || 0
  end
  
  def semantic_version
    Semantic::Version.new(version)
  rescue ArgumentError
    nil
  end
  
  def newer_version?(other_version)
    return false unless semantic_version
    
    other_semantic = Semantic::Version.new(other_version)
    semantic_version > other_semantic
  rescue ArgumentError
    false
  end
end
EOF
  
  # Create package build job
  mkdir -p app/jobs
  cat <<EOF > app/jobs/package_build_job.rb
class PackageBuildJob < ApplicationJob
  queue_as :default
  
  def perform(package)
    build_log = package.build_logs.create!(
      build_status: "building",
      log_content: "Build started at #{Time.current}",
      build_time: 0
    )
    
    start_time = Time.current
    
    begin
      # Simulate package build process
      result = simulate_build(package)
      
      build_time = ((Time.current - start_time) / 1.minute).round(2)
      
      build_log.update!(
        build_status: result[:status],
        log_content: result[:log],
        build_time: build_time
      )
      
      # Update package statistics
      update_build_statistics(package, result[:status])
      
      # Check for security vulnerabilities
      SecurityScanJob.perform_later(package) if result[:status] == "success"
      
    rescue => e
      build_log.update!(
        build_status: "failed",
        log_content: "Build failed: #{e.message}",
        build_time: ((Time.current - start_time) / 1.minute).round(2)
      )
    end
  end
  
  private
  
  def simulate_build(package)
    # Simplified build simulation
    log_content = []
    log_content << "Checking dependencies..."
    log_content << "Resolving package dependencies for #{package.name} v#{package.version}"
    
    # Check dependencies
    missing_deps = check_dependencies(package)
    if missing_deps.any?
      log_content << "Missing dependencies: #{missing_deps.join(', ')}"
      return { status: "failed", log: log_content.join("\n") }
    end
    
    log_content << "Dependencies satisfied"
    log_content << "Compiling source code..."
    
    # Simulate compilation time
    sleep(rand(1..3))
    
    # Random build success/failure
    if rand < 0.85 # 85% success rate
      log_content << "Compilation successful"
      log_content << "Running tests..."
      
      # Simulate testing
      sleep(rand(1..2))
      
      if rand < 0.9 # 90% test success rate
        log_content << "All tests passed"
        log_content << "Creating package..."
        log_content << "Package #{package.name} v#{package.version} built successfully"
        
        { status: "success", log: log_content.join("\n") }
      else
        log_content << "Some tests failed"
        { status: "failed", log: log_content.join("\n") }
      end
    else
      log_content << "Compilation failed"
      { status: "failed", log: log_content.join("\n") }
    end
  end
  
  def check_dependencies(package)
    missing_deps = []
    
    package.package_dependencies.each do |dep|
      unless dep.depends_on.build_logs.where(build_status: "success").exists?
        missing_deps << dep.depends_on.name
      end
    end
    
    missing_deps
  end
  
  def update_build_statistics(package, status)
    stats = package.package_statistics || package.create_package_statistics!
    
    # Update build success rate
    total_builds = package.build_logs.count
    successful_builds = package.build_logs.where(build_status: "success").count
    
    stats.update!(
      build_success_rate: (successful_builds.to_f / total_builds * 100).round(2)
    )
  end
end
EOF
  
  # Create enhanced home controller
  cat <<EOF > app/controllers/home_controller.rb
class HomeController < ApplicationController
  def index
    @cognitive_load = CognitiveLoadMonitor.new
    @complexity_assessment = @cognitive_load.assess_complexity(
      "BSDPorts home page with package statistics and build monitoring"
    )
    
    # Cognitive load management: limit to 7 key metrics
    @package_stats = {
      total_packages: Package.count,
      recent_builds: BuildLog.where("created_at > ?", 24.hours.ago).count,
      successful_builds: BuildLog.where(build_status: "success").where("created_at > ?", 24.hours.ago).count,
      security_alerts: SecurityAlert.count,
      active_maintainers: Package.distinct.count(:maintainer),
      total_downloads: PackageStatistics.sum(:download_count),
      categories: Package.distinct.count(:category)
    }
    
    @recent_packages = Package.recent.limit(5)
    @popular_packages = Package.popular.limit(5)
    @recent_builds = BuildLog.includes(:package).order(created_at: :desc).limit(10)
    
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
  
  # Create seed data for OpenBSD packages
  cat <<EOF > db/seeds.rb
# Create sample OpenBSD packages
packages = [
  {
    name: "nginx",
    version: "1.24.0",
    description: "High-performance HTTP server and reverse proxy",
    category: "www",
    maintainer: "maintainer@openbsd.org"
  },
  {
    name: "postgresql",
    version: "15.3",
    description: "Advanced object-relational database system",
    category: "databases",
    maintainer: "db-maintainer@openbsd.org"
  },
  {
    name: "ruby",
    version: "3.2.0",
    description: "Dynamic, open source programming language",
    category: "lang",
    maintainer: "ruby-maintainer@openbsd.org"
  },
  {
    name: "git",
    version: "2.41.0",
    description: "Distributed version control system",
    category: "devel",
    maintainer: "git-maintainer@openbsd.org"
  },
  {
    name: "vim",
    version: "9.0.1572",
    description: "Vi 'workalike' with many additional features",
    category: "editors",
    maintainer: "vim-maintainer@openbsd.org"
  }
]

admin_user = User.create!(
  email: "admin@bsdports.com",
  password: "password",
  password_confirmation: "password"
)

packages.each do |pkg_attrs|
  package = Package.create!(
    name: pkg_attrs[:name],
    version: pkg_attrs[:version],
    description: pkg_attrs[:description],
    category: pkg_attrs[:category],
    maintainer: pkg_attrs[:maintainer],
    user: admin_user
  )
  
  # Create statistics
  PackageStatistics.create!(
    package: package,
    download_count: rand(100..10000),
    build_success_rate: rand(80.0..99.9).round(2)
  )
  
  # Create sample build log
  BuildLog.create!(
    package: package,
    build_status: "success",
    log_content: "Build completed successfully for #{package.name} v#{package.version}",
    build_time: rand(1..30)
  )
end

# Create dependencies
nginx = Package.find_by(name: "nginx")
postgresql = Package.find_by(name: "postgresql")

if nginx && postgresql
  PackageDependency.create!(
    package: nginx,
    depends_on: postgresql,
    dependency_type: "runtime"
  )
end

puts "✅ BSDPorts seed data created successfully!"
puts "📦 #{Package.count} packages created"
puts "🔧 #{BuildLog.count} build logs created"
puts "📊 #{PackageStatistics.count} package statistics created"
EOF
  
  # Run seeds
  bin/rails db:seed
  
  log "BSDPorts application code generation completed" "INFO"
}

# Override main to use enhanced installation
main() {
  log "Starting BSDPorts installation with cognitive framework" "INFO"
  
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
    generate_application_code  # This will use our BSDPorts-specific implementation
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

bin/rails generate scaffold Package name:string version:string description:text user:references file:attachment
bin/rails generate scaffold Comment package:references user:references content:text

cat <<EOF > app/reflexes/packages_infinite_scroll_reflex.rb
class PackagesInfiniteScrollReflex < InfiniteScrollReflex
  def load_more
    @pagy, @collection = pagy(Package.all.order(created_at: :desc), page: page)
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

cat <<EOF > app/controllers/packages_controller.rb
class PackagesController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_package, only: [:show, :edit, :update, :destroy]

  def index
    @pagy, @packages = pagy(Package.all.order(created_at: :desc)) unless @stimulus_reflex
  end

  def show
  end

  def new
    @package = Package.new
  end

  def create
    @package = Package.new(package_params)
    @package.user = current_user
    if @package.save
      respond_to do |format|
        format.html { redirect_to packages_path, notice: t("bsdports.package_created") }
        format.turbo_stream
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @package.update(package_params)
      respond_to do |format|
        format.html { redirect_to packages_path, notice: t("bsdports.package_updated") }
        format.turbo_stream
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @package.destroy
    respond_to do |format|
      format.html { redirect_to packages_path, notice: t("bsdports.package_deleted") }
      format.turbo_stream
    end
  end

  private

  def set_package
    @package = Package.find(params[:id])
    redirect_to packages_path, alert: t("bsdports.not_authorized") unless @package.user == current_user || current_user&.admin?
  end

  def package_params
    params.require(:package).permit(:name, :version, :description, :file)
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
        format.html { redirect_to comments_path, notice: t("bsdports.comment_created") }
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
        format.html { redirect_to comments_path, notice: t("bsdports.comment_updated") }
        format.turbo_stream
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @comment.destroy
    respond_to do |format|
      format.html { redirect_to comments_path, notice: t("bsdports.comment_deleted") }
      format.turbo_stream
    end
  end

  private

  def set_comment
    @comment = Comment.find(params[:id])
    redirect_to comments_path, alert: t("bsdports.not_authorized") unless @comment.user == current_user || current_user&.admin?
  end

  def comment_params
    params.require(:comment).permit(:package_id, :content)
  end
end
EOF

cat <<EOF > app/controllers/home_controller.rb
class HomeController < ApplicationController
  def index
    @pagy, @posts = pagy(Post.all.order(created_at: :desc), items: 10) unless @stimulus_reflex
    @packages = Package.all.order(created_at: :desc).limit(5)
  end
end
EOF

mkdir -p app/views/bsdports_logo

cat <<EOF > app/views/bsdports_logo/_logo.html.erb
<%= tag.svg xmlns: "http://www.w3.org/2000/svg", viewBox: "0 0 100 50", role: "img", class: "logo", "aria-label": t("bsdports.logo_alt") do %>
  <%= tag.title t("bsdports.logo_title", default: "BSDPorts Logo") %>
  <%= tag.text x: "50", y: "30", "text-anchor": "middle", "font-family": "Helvetica, Arial, sans-serif", "font-size": "16", fill: "#2196f3" do %>BSDPorts<% end %>
<% end %>
EOF

cat <<EOF > app/views/shared/_header.html.erb
<%= tag.header role: "banner" do %>
  <%= render partial: "bsdports_logo/logo" %>
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
<% content_for :title, t("bsdports.home_title") %>
<% content_for :description, t("bsdports.home_description") %>
<% content_for :keywords, t("bsdports.home_keywords", default: "bsdports, packages, software") %>
<% content_for :schema do %>
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "WebPage",
    "name": "<%= t('bsdports.home_title') %>",
    "description": "<%= t('bsdports.home_description') %>",
    "url": "<%= request.original_url %>",
    "publisher": {
      "@type": "Organization",
      "name": "BSDPorts",
      "logo": {
        "@type": "ImageObject",
        "url": "<%= image_url('bsdports_logo.svg') %>"
      }
    }
  }
  </script>
<% end %>
<%= render "shared/header" %>
<%= tag.main role: "main" do %>
  <%= tag.section aria-labelledby: "post-heading" do %>
    <%= tag.h1 t("bsdports.post_title"), id: "post-heading" %>
    <%= tag.div data: { turbo_frame: "notices" } do %>
      <%= render "shared/notices" %>
    <% end %>
    <%= render partial: "posts/form", locals: { post: Post.new } %>
  <% end %>
  <%= render partial: "shared/search", locals: { model: "Package", field: "name" } %>
  <%= tag.section aria-labelledby: "packages-heading" do %>
    <%= tag.h2 t("bsdports.packages_title"), id: "packages-heading" %>
    <%= link_to t("bsdports.new_package"), new_package_path, class: "button", "aria-label": t("bsdports.new_package") if current_user %>
    <%= turbo_frame_tag "packages" data: { controller: "infinite-scroll" } do %>
      <% @packages.each do |package| %>
        <%= render partial: "packages/card", locals: { package: package } %>
      <% end %>
      <%= tag.div id: "sentinel", class: "hidden", data: { reflex: "PackagesInfiniteScroll#load_more", next_page: @pagy.next || 2 } %>
    <% end %>
    <%= tag.button t("bsdports.load_more"), id: "load-more", data: { reflex: "click->PackagesInfiniteScroll#load_more", "next-page": @pagy.next || 2, "reflex-root": "#load-more" }, class: @pagy&.next ? "" : "hidden", "aria-label": t("bsdports.load_more") %>
  <% end %>
  <%= tag.section aria-labelledby: "posts-heading" do %>
    <%= tag.h2 t("bsdports.posts_title"), id: "posts-heading" %>
    <%= turbo_frame_tag "posts" data: { controller: "infinite-scroll" } do %>
      <% @posts.each do |post| %>
        <%= render partial: "posts/card", locals: { post: post } %>
      <% end %>
      <%= tag.div id: "sentinel", class: "hidden", data: { reflex: "PostsInfiniteScroll#load_more", next_page: @pagy.next || 2 } %>
    <% end %>
    <%= tag.button t("bsdports.load_more"), id: "load-more", data: { reflex: "click->PostsInfiniteScroll#load_more", "next-page": @pagy.next || 2, "reflex-root": "#load-more" }, class: @pagy&.next ? "" : "hidden", "aria-label": t("bsdports.load_more") %>
  <% end %>
  <%= render partial: "shared/chat" %>
<% end %>
<%= render "shared/footer" %>
EOF

cat <<EOF > app/views/packages/index.html.erb
<% content_for :title, t("bsdports.packages_title") %>
<% content_for :description, t("bsdports.packages_description") %>
<% content_for :keywords, t("bsdports.packages_keywords", default: "bsdports, packages, software") %>
<% content_for :schema do %>
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "WebPage",
    "name": "<%= t('bsdports.packages_title') %>",
    "description": "<%= t('bsdports.packages_description') %>",
    "url": "<%= request.original_url %>",
    "hasPart": [
      <% @packages.each do |package| %>
      {
        "@type": "SoftwareApplication",
        "name": "<%= package.name %>",
        "softwareVersion": "<%= package.version %>",
        "description": "<%= package.description&.truncate(160) %>"
      }<%= "," unless package == @packages.last %>
      <% end %>
    ]
  }
  </script>
<% end %>
<%= render "shared/header" %>
<%= tag.main role: "main" do %>
  <%= tag.section aria-labelledby: "packages-heading" do %>
    <%= tag.h1 t("bsdports.packages_title"), id: "packages-heading" %>
    <%= tag.div data: { turbo_frame: "notices" } do %>
      <%= render "shared/notices" %>
    <% end %>
    <%= link_to t("bsdports.new_package"), new_package_path, class: "button", "aria-label": t("bsdports.new_package") if current_user %>
    <%= turbo_frame_tag "packages" data: { controller: "infinite-scroll" } do %>
      <% @packages.each do |package| %>
        <%= render partial: "packages/card", locals: { package: package } %>
      <% end %>
      <%= tag.div id: "sentinel", class: "hidden", data: { reflex: "PackagesInfiniteScroll#load_more", next_page: @pagy.next || 2 } %>
    <% end %>
    <%= tag.button t("bsdports.load_more"), id: "load-more", data: { reflex: "click->PackagesInfiniteScroll#load_more", "next-page": @pagy.next || 2, "reflex-root": "#load-more" }, class: @pagy&.next ? "" : "hidden", "aria-label": t("bsdports.load_more") %>
  <% end %>
  <%= render partial: "shared/search", locals: { model: "Package", field: "name" } %>
<% end %>
<%= render "shared/footer" %>
EOF

cat <<EOF > app/views/packages/_card.html.erb
<%= turbo_frame_tag dom_id(package) do %>
  <%= tag.article class: "post-card", id: dom_id(package), role: "article" do %>
    <%= tag.div class: "post-header" do %>
      <%= tag.span t("bsdports.posted_by", user: package.user.email) %>
      <%= tag.span package.created_at.strftime("%Y-%m-%d %H:%M") %>
    <% end %>
    <%= tag.h2 package.name %>
    <%= tag.p t("bsdports.package_version", version: package.version) %>
    <%= tag.p package.description %>
    <% if package.file.attached? %>
      <%= link_to t("bsdports.download_file"), rails_blob_path(package.file, disposition: "attachment"), "aria-label": t("bsdports.download_file_alt", name: package.name) %>
    <% end %>
    <%= render partial: "shared/vote", locals: { votable: package } %>
    <%= tag.p class: "post-actions" do %>
      <%= link_to t("bsdports.view_package"), package_path(package), "aria-label": t("bsdports.view_package") %>
      <%= link_to t("bsdports.edit_package"), edit_package_path(package), "aria-label": t("bsdports.edit_package") if package.user == current_user || current_user&.admin? %>
      <%= button_to t("bsdports.delete_package"), package_path(package), method: :delete, data: { turbo_confirm: t("bsdports.confirm_delete") }, form: { data: { turbo_frame: "_top" } }, "aria-label": t("bsdports.delete_package") if package.user == current_user || current_user&.admin? %>
    <% end %>
  <% end %>
<% end %>
EOF

cat <<EOF > app/views/packages/_form.html.erb
<%= form_with model: package, local: true, data: { controller: "character-counter form-validation", turbo: true } do |form| %>
  <%= tag.div data: { turbo_frame: "notices" } do %>
    <%= render "shared/notices" %>
  <% end %>
  <% if package.errors.any? %>
    <%= tag.div role: "alert" do %>
      <%= tag.p t("bsdports.errors", count: package.errors.count) %>
      <%= tag.ul do %>
        <% package.errors.full_messages.each do |msg| %>
          <%= tag.li msg %>
        <% end %>
      <% end %>
    <% end %>
  <% end %>
  <%= tag.fieldset do %>
    <%= form.label :name, t("bsdports.package_name"), "aria-required": true %>
    <%= form.text_field :name, required: true, data: { "form-validation-target": "input", action: "input->form-validation#validate" }, title: t("bsdports.package_name_help") %>
    <%= tag.span class: "error-message" data: { "form-validation-target": "error", for: "package_name" } %>
  <% end %>
  <%= tag.fieldset do %>
    <%= form.label :version, t("bsdports.package_version"), "aria-required": true %>
    <%= form.text_field :version, required: true, data: { "form-validation-target": "input", action: "input->form-validation#validate" }, title: t("bsdports.package_version_help") %>
    <%= tag.span class: "error-message" data: { "form-validation-target": "error", for: "package_version" } %>
  <% end %>
  <%= tag.fieldset do %>
    <%= form.label :description, t("bsdports.package_description"), "aria-required": true %>
    <%= form.text_area :description, required: true, data: { "character-counter-target": "input", "textarea-autogrow-target": "input", "form-validation-target": "input", action: "input->character-counter#count input->textarea-autogrow#resize input->form-validation#validate" }, title: t("bsdports.package_description_help") %>
    <%= tag.span data: { "character-counter-target": "count" } %>
    <%= tag.span class: "error-message" data: { "form-validation-target": "error", for: "package_description" } %>
  <% end %>
  <%= tag.fieldset do %>
    <%= form.label :file, t("bsdports.package_file"), "aria-required": true %>
    <%= form.file_field :file, required: !package.persisted?, data: { controller: "file-preview", "file-preview-target": "input" } %>
    <% if package.file.attached? %>
      <%= link_to t("bsdports.current_file"), rails_blob_path(package.file, disposition: "attachment"), "aria-label": t("bsdports.current_file_alt", name: package.name) %>
    <% end %>
    <%= tag.div data: { "file-preview-target": "preview" }, style: "display: none;" %>
  <% end %>
  <%= form.submit t("bsdports.#{package.persisted? ? 'update' : 'create'}_package"), data: { turbo_submits_with: t("bsdports.#{package.persisted? ? 'updating' : 'creating'}_package") } %>
<% end %>
EOF

cat <<EOF > app/views/packages/new.html.erb
<% content_for :title, t("bsdports.new_package_title") %>
<% content_for :description, t("bsdports.new_package_description") %>
<% content_for :keywords, t("bsdports.new_package_keywords", default: "add package, bsdports, software") %>
<% content_for :schema do %>
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "WebPage",
    "name": "<%= t('bsdports.new_package_title') %>",
    "description": "<%= t('bsdports.new_package_description') %>",
    "url": "<%= request.original_url %>"
  }
  </script>
<% end %>
<%= render "shared/header" %>
<%= tag.main role: "main" do %>
  <%= tag.section aria-labelledby: "new-package-heading" do %>
    <%= tag.h1 t("bsdports.new_package_title"), id: "new-package-heading" %>
    <%= render partial: "packages/form", locals: { package: @package } %>
  <% end %>
<% end %>
<%= render "shared/footer" %>
EOF

cat <<EOF > app/views/packages/edit.html.erb
<% content_for :title, t("bsdports.edit_package_title") %>
<% content_for :description, t("bsdports.edit_package_description") %>
<% content_for :keywords, t("bsdports.edit_package_keywords", default: "edit package, bsdports, software") %>
<% content_for :schema do %>
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "WebPage",
    "name": "<%= t('bsdports.edit_package_title') %>",
    "description": "<%= t('bsdports.edit_package_description') %>",
    "url": "<%= request.original_url %>"
  }
  </script>
<% end %>
<%= render "shared/header" %>
<%= tag.main role: "main" do %>
  <%= tag.section aria-labelledby: "edit-package-heading" do %>
    <%= tag.h1 t("bsdports.edit_package_title"), id: "edit-package-heading" %>
    <%= render partial: "packages/form", locals: { package: @package } %>
  <% end %>
<% end %>
<%= render "shared/footer" %>
EOF

cat <<EOF > app/views/packages/show.html.erb
<% content_for :title, @package.name %>
<% content_for :description, @package.description&.truncate(160) %>
<% content_for :keywords, t("bsdports.package_keywords", name: @package.name, default: "package, #{@package.name}, bsdports, software") %>
<% content_for :schema do %>
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "SoftwareApplication",
    "name": "<%= @package.name %>",
    "softwareVersion": "<%= @package.version %>",
    "description": "<%= @package.description&.truncate(160) %>"
  }
  </script>
<% end %>
<%= render "shared/header" %>
<%= tag.main role: "main" do %>
  <%= tag.section aria-labelledby: "package-heading" class: "post-card" do %>
    <%= tag.div data: { turbo_frame: "notices" } do %>
      <%= render "shared/notices" %>
    <% end %>
    <%= tag.h1 @package.name, id: "package-heading" %>
    <%= render partial: "packages/card", locals: { package: @package } %>
  <% end %>
<% end %>
<%= render "shared/footer" %>
EOF

cat <<EOF > app/views/comments/index.html.erb
<% content_for :title, t("bsdports.comments_title") %>
<% content_for :description, t("bsdports.comments_description") %>
<% content_for :keywords, t("bsdports.comments_keywords", default: "bsdports, comments, software") %>
<% content_for :schema do %>
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "WebPage",
    "name": "<%= t('bsdports.comments_title') %>",
    "description": "<%= t('bsdports.comments_description') %>",
    "url": "<%= request.original_url %>"
  }
  </script>
<% end %>
<%= render "shared/header" %>
<%= tag.main role: "main" do %>
  <%= tag.section aria-labelledby: "comments-heading" do %>
    <%= tag.h1 t("bsdports.comments_title"), id: "comments-heading" %>
    <%= tag.div data: { turbo_frame: "notices" } do %>
      <%= render "shared/notices" %>
    <% end %>
    <%= link_to t("bsdports.new_comment"), new_comment_path, class: "button", "aria-label": t("bsdports.new_comment") %>
    <%= turbo_frame_tag "comments" data: { controller: "infinite-scroll" } do %>
      <% @comments.each do |comment| %>
        <%= render partial: "comments/card", locals: { comment: comment } %>
      <% end %>
      <%= tag.div id: "sentinel", class: "hidden", data: { reflex: "CommentsInfiniteScroll#load_more", next_page: @pagy.next || 2 } %>
    <% end %>
    <%= tag.button t("bsdports.load_more"), id: "load-more", data: { reflex: "click->CommentsInfiniteScroll#load_more", "next-page": @pagy.next || 2, "reflex-root": "#load-more" }, class: @pagy&.next ? "" : "hidden", "aria-label": t("bsdports.load_more") %>
  <% end %>
<% end %>
<%= render "shared/footer" %>
EOF

cat <<EOF > app/views/comments/_card.html.erb
<%= turbo_frame_tag dom_id(comment) do %>
  <%= tag.article class: "post-card", id: dom_id(comment), role: "article" do %>
    <%= tag.div class: "post-header" do %>
      <%= tag.span t("bsdports.posted_by", user: comment.user.email) %>
      <%= tag.span comment.created_at.strftime("%Y-%m-%d %H:%M") %>
    <% end %>
    <%= tag.h2 comment.package.name %>
    <%= tag.p comment.content %>
    <%= render partial: "shared/vote", locals: { votable: comment } %>
    <%= tag.p class: "post-actions" do %>
      <%= link_to t("bsdports.view_comment"), comment_path(comment), "aria-label": t("bsdports.view_comment") %>
      <%= link_to t("bsdports.edit_comment"), edit_comment_path(comment), "aria-label": t("bsdports.edit_comment") if comment.user == current_user || current_user&.admin? %>
      <%= button_to t("bsdports.delete_comment"), comment_path(comment), method: :delete, data: { turbo_confirm: t("bsdports.confirm_delete") }, form: { data: { turbo_frame: "_top" } }, "aria-label": t("bsdports.delete_comment") if comment.user == current_user || current_user&.admin? %>
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
      <%= tag.p t("bsdports.errors", count: comment.errors.count) %>
      <%= tag.ul do %>
        <% comment.errors.full_messages.each do |msg| %>
          <%= tag.li msg %>
        <% end %>
      <% end %>
    <% end %>
  <% end %>
  <%= tag.fieldset do %>
    <%= form.label :package_id, t("bsdports.comment_package"), "aria-required": true %>
    <%= form.collection_select :package_id, Package.all, :id, :name, { prompt: t("bsdports.package_prompt") }, required: true %>
    <%= tag.span class: "error-message" data: { "form-validation-target": "error", for: "comment_package_id" } %>
  <% end %>
  <%= tag.fieldset do %>
    <%= form.label :content, t("bsdports.comment_content"), "aria-required": true %>
    <%= form.text_area :content, required: true, data: { "character-counter-target": "input", "textarea-autogrow-target": "input", "form-validation-target": "input", action: "input->character-counter#count input->textarea-autogrow#resize input->form-validation#validate" }, title: t("bsdports.comment_content_help") %>
    <%= tag.span data: { "character-counter-target": "count" } %>
    <%= tag.span class: "error-message" data: { "form-validation-target": "error", for: "comment_content" } %>
  <% end %>
  <%= form.submit t("bsdports.#{comment.persisted? ? 'update' : 'create'}_comment"), data: { turbo_submits_with: t("bsdports.#{comment.persisted? ? 'updating' : 'creating'}_comment") } %>
<% end %>
EOF

cat <<EOF > app/views/comments/new.html.erb
<% content_for :title, t("bsdports.new_comment_title") %>
<% content_for :description, t("bsdports.new_comment_description") %>
<% content_for :keywords, t("bsdports.new_comment_keywords", default: "add comment, bsdports, software") %>
<% content_for :schema do %>
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "WebPage",
    "name": "<%= t('bsdports.new_comment_title') %>",
    "description": "<%= t('bsdports.new_comment_description') %>",
    "url": "<%= request.original_url %>"
  }
  </script>
<% end %>
<%= render "shared/header" %>
<%= tag.main role: "main" do %>
  <%= tag.section aria-labelledby: "new-comment-heading" do %>
    <%= tag.h1 t("bsdports.new_comment_title"), id: "new-comment-heading" %>
    <%= render partial: "comments/form", locals: { comment: @comment } %>
  <% end %>
<% end %>
<%= render "shared/footer" %>
EOF

cat <<EOF > app/views/comments/edit.html.erb
<% content_for :title, t("bsdports.edit_comment_title") %>
<% content_for :description, t("bsdports.edit_comment_description") %>
<% content_for :keywords, t("bsdports.edit_comment_keywords", default: "edit comment, bsdports, software") %>
<% content_for :schema do %>
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "WebPage",
    "name": "<%= t('bsdports.edit_comment_title') %>",
    "description": "<%= t('bsdports.edit_comment_description') %>",
    "url": "<%= request.original_url %>"
  }
  </script>
<% end %>
<%= render "shared/header" %>
<%= tag.main role: "main" do %>
  <%= tag.section aria-labelledby: "edit-comment-heading" do %>
    <%= tag.h1 t("bsdports.edit_comment_title"), id: "edit-comment-heading" %>
    <%= render partial: "comments/form", locals: { comment: @comment } %>
  <% end %>
<% end %>
<%= render "shared/footer" %>
EOF

cat <<EOF > app/views/comments/show.html.erb
<% content_for :title, t("bsdports.comment_title", package: @comment.package.name) %>
<% content_for :description, @comment.content&.truncate(160) %>
<% content_for :keywords, t("bsdports.comment_keywords", package: @comment.package.name, default: "comment, #{@comment.package.name}, bsdports, software") %>
<% content_for :schema do %>
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "Comment",
    "text": "<%= @comment.content&.truncate(160) %>",
    "about": {
      "@type": "SoftwareApplication",
      "name": "<%= @comment.package.name %>"
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
    <%= tag.h1 t("bsdports.comment_title", package: @comment.package.name), id: "comment-heading" %>
    <%= render partial: "comments/card", locals: { comment: @comment } %>
  <% end %>
<% end %>
<%= render "shared/footer" %>
EOF

generate_turbo_views "packages" "package"
generate_turbo_views "comments" "comment"

commit "BSDPorts setup complete: Software package sharing platform with live search and anonymous features"

log "BSDPorts setup complete. Run 'bin/falcon-host' with PORT set to start on OpenBSD."

# Change Log:
# - Aligned with master.json v6.5.0: Two-space indents, double quotes, heredocs, Strunk & White comments.
# - Used Rails 8 conventions, Hotwire, Turbo Streams, Stimulus Reflex, I18n, and Falcon.
# - Leveraged bin/rails generate scaffold for Packages and Comments to streamline CRUD setup.
# - Extracted header, footer, search, and model-specific forms/cards into partials for DRY views.
# - Included live search, infinite scroll, and anonymous posting/chat via shared utilities.
# - Ensured NNG principles, SEO, schema data, and minimal flat design compliance.
# - Finalized for unprivileged user on OpenBSD 7.5.