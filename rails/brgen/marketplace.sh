#!/bin/bash

#!/usr/bin/env zsh
set -euo pipefail

# Brgen Marketplace setup: E-commerce platform with live search, infinite scroll, and anonymous features on OpenBSD 7.5, unprivileged user

APP_NAME="brgen_marketplace"
BASE_DIR="/home/dev/rails"
BRGEN_IP="46.23.95.45"

source "./__shared.sh"

log "Starting Brgen Marketplace setup"

setup_full_app "$APP_NAME"

command_exists "ruby"
command_exists "node"
command_exists "psql"
command_exists "redis-server"

# Generate enhanced models with SEO and karma support
bin/rails generate scaffold Product name:string slug:string price:decimal description:text user:references photos:attachments category:string condition:string karma_score:integer view_count:integer sold:boolean
bin/rails generate scaffold Order product:references buyer:references status:string total:decimal shipping_address:text notes:text
bin/rails generate scaffold ProductReview product:references user:references rating:integer content:text helpful_count:integer
bin/rails generate scaffold ProductFavorite product:references user:references
bin/rails generate scaffold ProductQuestion product:references user:references question:text answer:text

# Add karma and reputation tracking for marketplace features
bin/rails generate model MarketplaceKarma user:references product_karma:integer review_karma:integer question_karma:integer sale_karma:integer total_karma:integer level:integer

# Enhanced infinite scroll reflexes with analytics and social features
cat <<EOF > app/reflexes/products_infinite_scroll_reflex.rb
class ProductsInfiniteScrollReflex < InfiniteScrollReflex
  def load_more
    @pagy, @collection = pagy(
      Product.includes(:user, :photos_attachments, :product_favorites)
             .where(tenant: ActsAsTenant.current_tenant, sold: false)
             .order(created_at: :desc), 
      page: page
    )
    ahoy.track "Products infinite scroll", { page: page, tenant: ActsAsTenant.current_tenant&.name }
    super
  end
end
EOF

cat <<EOF > app/reflexes/orders_infinite_scroll_reflex.rb
class OrdersInfiniteScrollReflex < InfiniteScrollReflex
  def load_more
    @pagy, @collection = pagy(Order.includes(:product, :buyer).where(buyer: current_user).order(created_at: :desc), page: page)
    ahoy.track "Orders infinite scroll", { page: page }
    super
  end
end
EOF

# Enhanced product voting system
cat <<EOF > app/reflexes/product_vote_reflex.rb
class ProductVoteReflex < ApplicationReflex
  def upvote
    product = Product.find(element.dataset["product_id"])
    vote = current_user.votes.find_or_initialize_by(votable: product)
    
    if vote.persisted? && vote.vote_flag
      # Already upvoted, remove vote
      vote.destroy
      KarmaAction.create!(user: product.user, target: product, action_type: 'vote_removed', points: -1)
    else
      # Create or change to upvote
      vote.destroy if vote.persisted?
      product.upvote_by current_user
      KarmaAction.create!(user: product.user, target: product, action_type: 'upvote', points: 3)
      
      # Update user karma
      karma = product.user.marketplace_karma || product.user.create_marketplace_karma
      karma.increment!(:product_karma, 3)
      karma.update!(total_karma: karma.product_karma + karma.review_karma + karma.question_karma + karma.sale_karma)
    end
    
    ahoy.track "Product vote", { product_id: product.id, action: 'upvote' }
    cable_ready.replace(selector: "#product-vote-#{product.id}", html: render(partial: "shared/vote_buttons", locals: { votable: product })).broadcast
  end

  def downvote
    product = Product.find(element.dataset["product_id"])
    vote = current_user.votes.find_or_initialize_by(votable: product)
    
    if vote.persisted? && !vote.vote_flag
      # Already downvoted, remove vote  
      vote.destroy
      KarmaAction.create!(user: product.user, target: product, action_type: 'vote_removed', points: 1)
    else
      # Create or change to downvote
      vote.destroy if vote.persisted?
      product.downvote_by current_user
      KarmaAction.create!(user: product.user, target: product, action_type: 'downvote', points: -1)
      
      # Update user karma
      karma = product.user.marketplace_karma || product.user.create_marketplace_karma
      karma.decrement!(:product_karma, 1)
      karma.update!(total_karma: karma.product_karma + karma.review_karma + karma.question_karma + karma.sale_karma)
    end
    
    ahoy.track "Product vote", { product_id: product.id, action: 'downvote' }
    cable_ready.replace(selector: "#product-vote-#{product.id}", html: render(partial: "shared/vote_buttons", locals: { votable: product })).broadcast
  end
end
EOF

# Product favorite/unfavorite reflex
cat <<EOF > app/reflexes/product_favorite_reflex.rb
class ProductFavoriteReflex < ApplicationReflex
  def toggle_favorite
    product = Product.find(element.dataset["product_id"])
    favorite = current_user.product_favorites.find_by(product: product)
    
    if favorite
      # Remove from favorites
      favorite.destroy
      action = 'unfavorited'
    else
      # Add to favorites
      current_user.product_favorites.create!(product: product)
      KarmaAction.create!(user: product.user, target: product, action_type: 'favorited', points: 1)
      action = 'favorited'
    end
    
    ahoy.track "Product favorite", { product_id: product.id, action: action }
    cable_ready.replace(selector: "#product-favorite-#{product.id}", html: render(partial: "products/favorite_button", locals: { product: product })).broadcast
  end
end
EOF

# Enhanced controllers with analytics and SEO
cat <<EOF > app/controllers/products_controller.rb
class ProductsController < ApplicationController
  include AnalyticsTracking
  include GitTracking
  
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_product, only: [:show, :edit, :update, :destroy, :mark_sold]

  def index
    @pagy, @products = pagy(
      Product.includes(:user, :photos_attachments, :product_favorites)
             .where(tenant: ActsAsTenant.current_tenant, sold: false)
             .order(created_at: :desc)
    ) unless @stimulus_reflex
    
    # Filter by category if specified
    if params[:category].present?
      @products = @products.where(category: params[:category])
    end
    
    # Filter by condition if specified
    if params[:condition].present?
      @products = @products.where(condition: params[:condition])
    end
    
    # SEO optimization
    @seo_title = "Marketplace - #{ActsAsTenant.current_tenant&.name || 'Brgen Marketplace'}"
    @seo_description = "Buy and sell items in your local community"
    @seo_keywords = "marketplace, buy, sell, local, community, #{ActsAsTenant.current_tenant&.name}"
    
    ahoy.track "Products index", { 
      products_count: @products&.count || 0,
      tenant: ActsAsTenant.current_tenant&.name,
      category: params[:category],
      condition: params[:condition]
    }
  end

  def show
    @reviews = @product.product_reviews.includes(:user).order(created_at: :desc).limit(10)
    @questions = @product.product_questions.includes(:user).order(created_at: :desc).limit(5)
    @user_review = current_user&.product_reviews&.find_by(product: @product)
    @is_favorited = current_user&.product_favorites&.exists?(product: @product)
    @related_products = Product.where(category: @product.category, tenant: ActsAsTenant.current_tenant)
                               .where.not(id: @product.id)
                               .where(sold: false)
                               .limit(4)
    
    # Increment view count
    @product.increment!(:view_count)
    
    # SEO for individual product
    @seo_title = @product.name
    @seo_description = truncate(@product.description, length: 160)
    @seo_keywords = "#{@product.category}, #{@product.condition}, #{@product.name}, marketplace"
    
    # Schema.org structured data
    @schema_data = {
      "@context" => "https://schema.org",
      "@type" => "Product",
      "name" => @product.name,
      "description" => @product.description,
      "category" => @product.category,
      "offers" => {
        "@type" => "Offer",
        "price" => @product.price,
        "priceCurrency" => "NOK",
        "availability" => @product.sold? ? "OutOfStock" : "InStock",
        "seller" => {
          "@type" => "Person", 
          "name" => @product.user.email
        }
      },
      "aggregateRating" => {
        "@type" => "AggregateRating",
        "ratingValue" => @product.average_rating,
        "reviewCount" => @reviews.count
      }
    }
    
    ahoy.track "Product view", { 
      product_id: @product.id,
      product_name: @product.name,
      category: @product.category,
      price: @product.price
    }
  end

  def new
    @product = current_user.products.build
  end

  def create
    @product = current_user.products.build(product_params)
    @product.tenant = ActsAsTenant.current_tenant
    @product.slug = @product.name.parameterize if @product.name
    
    if @product.save
      # Award karma for content creation
      karma = current_user.marketplace_karma || current_user.create_marketplace_karma
      karma.increment!(:product_karma, 10)
      karma.update!(total_karma: karma.product_karma + karma.review_karma + karma.question_karma + karma.sale_karma)
      
      KarmaAction.create!(user: current_user, target: @product, action_type: 'content_created', points: 10)
      
      ahoy.track "Product created", { product_id: @product.id, name: @product.name, category: @product.category }
      PublicActivity::Activity.create!(trackable: @product, owner: current_user, key: 'product.create')
      
      redirect_to @product, notice: 'Product was successfully created.'
    else
      render :new
    end
  end

  def edit
    redirect_to @product, alert: 'Not authorized' unless @product.user == current_user
  end

  def update
    if @product.update(product_params)
      @product.update(slug: @product.name.parameterize) if product_params[:name]
      ahoy.track "Product updated", { product_id: @product.id, name: @product.name }
      PublicActivity::Activity.create!(trackable: @product, owner: current_user, key: 'product.update')
      redirect_to @product, notice: 'Product was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    product_name = @product.name
    @product.destroy
    ahoy.track "Product deleted", { name: product_name }
    redirect_to products_url, notice: 'Product was successfully deleted.'
  end

  def mark_sold
    if @product.user == current_user
      @product.update!(sold: true)
      
      # Award karma for successful sale
      karma = current_user.marketplace_karma || current_user.create_marketplace_karma
      karma.increment!(:sale_karma, 5)
      karma.update!(total_karma: karma.product_karma + karma.review_karma + karma.question_karma + karma.sale_karma)
      
      KarmaAction.create!(user: current_user, target: @product, action_type: 'item_sold', points: 5)
      ahoy.track "Product sold", { product_id: @product.id, name: @product.name }
      
      redirect_to @product, notice: 'Product marked as sold!'
    else
      redirect_to @product, alert: 'Not authorized'
    end
  end

  private

  def set_product
    @product = Product.friendly.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    @product = Product.find(params[:id])
  end

  def product_params
    params.require(:product).permit(:name, :price, :description, :category, :condition, photos: [])
  end
end
EOF

# Enhanced orders controller
cat <<EOF > app/controllers/orders_controller.rb
class OrdersController < ApplicationController
  include AnalyticsTracking
  include GitTracking
  
  before_action :authenticate_user!
  before_action :set_order, only: [:show, :update, :cancel]

  def index
    @pagy, @orders = pagy(
      current_user.orders.includes(:product).order(created_at: :desc)
    ) unless @stimulus_reflex
    
    ahoy.track "Orders index", { orders_count: @orders&.count || 0 }
  end

  def show
    ahoy.track "Order view", { 
      order_id: @order.id,
      product_id: @order.product.id,
      status: @order.status
    }
  end

  def create
    @product = Product.find(params[:product_id])
    @order = current_user.orders.build(
      product: @product,
      total: @product.price,
      status: 'pending'
    )
    
    if @order.save
      # Notify seller
      # Could integrate with notification system here
      
      ahoy.track "Order created", {
        order_id: @order.id,
        product_id: @product.id,
        total: @order.total
      }
      
      redirect_to @order, notice: 'Order was successfully placed!'
    else
      redirect_to @product, alert: 'Failed to place order. Please try again.'
    end
  end

  def update
    if @order.update(order_params)
      ahoy.track "Order updated", { order_id: @order.id, status: @order.status }
      redirect_to @order, notice: 'Order was successfully updated.'
    else
      render :show
    end
  end

  def cancel
    if @order.status == 'pending'
      @order.update!(status: 'cancelled')
      ahoy.track "Order cancelled", { order_id: @order.id }
      redirect_to orders_path, notice: 'Order was cancelled.'
    else
      redirect_to @order, alert: 'Cannot cancel order in current status.'
    end
  end

  private

  def set_order
    @order = current_user.orders.find(params[:id])
  end

  def order_params
    params.require(:order).permit(:shipping_address, :notes)
  end
end
EOF
  end

  def show
  end

  def new
    @product = Product.new
  end

  def create
    @product = Product.new(product_params)
    @product.user = current_user
    if @product.save
      respond_to do |format|
        format.html { redirect_to products_path, notice: t("brgen_marketplace.product_created") }
        format.turbo_stream
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @product.update(product_params)
      respond_to do |format|
        format.html { redirect_to products_path, notice: t("brgen_marketplace.product_updated") }
        format.turbo_stream
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @product.destroy
    respond_to do |format|
      format.html { redirect_to products_path, notice: t("brgen_marketplace.product_deleted") }
      format.turbo_stream
    end
  end

  private

  def set_product
    @product = Product.find(params[:id])
    redirect_to products_path, alert: t("brgen_marketplace.not_authorized") unless @product.user == current_user || current_user&.admin?
  end

  def product_params
    params.require(:product).permit(:name, :price, :description, photos: [])
  end
end
EOF

cat <<EOF > app/controllers/orders_controller.rb
class OrdersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_order, only: [:show, :edit, :update, :destroy]

  def index
    @pagy, @orders = pagy(Order.where(buyer: current_user).order(created_at: :desc)) unless @stimulus_reflex
  end

  def show
  end

  def new
    @order = Order.new
  end

  def create
    @order = Order.new(order_params)
    @order.buyer = current_user
    if @order.save
      respond_to do |format|
        format.html { redirect_to orders_path, notice: t("brgen_marketplace.order_created") }
        format.turbo_stream
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @order.update(order_params)
      respond_to do |format|
        format.html { redirect_to orders_path, notice: t("brgen_marketplace.order_updated") }
        format.turbo_stream
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @order.destroy
    respond_to do |format|
      format.html { redirect_to orders_path, notice: t("brgen_marketplace.order_deleted") }
      format.turbo_stream
    end
  end

  private

  def set_order
    @order = Order.where(buyer: current_user).find(params[:id])
    redirect_to orders_path, alert: t("brgen_marketplace.not_authorized") unless @order.buyer == current_user || current_user&.admin?
  end

  def order_params
    params.require(:order).permit(:product_id, :status)
  end
end
EOF

cat <<EOF > app/controllers/home_controller.rb
class HomeController < ApplicationController
  def index
    @pagy, @posts = pagy(Post.all.order(created_at: :desc), items: 10) unless @stimulus_reflex
    @products = Product.all.order(created_at: :desc).limit(5)
  end
end
EOF

mkdir -p app/views/brgen_marketplace_logo

cat <<EOF > app/views/brgen_marketplace_logo/_logo.html.erb
<%= tag.svg xmlns: "http://www.w3.org/2000/svg", viewBox: "0 0 100 50", role: "img", class: "logo", "aria-label": t("brgen_marketplace.logo_alt") do %>
  <%= tag.title t("brgen_marketplace.logo_title", default: "Brgen Marketplace Logo") %>
  <%= tag.text x: "50", y: "30", "text-anchor": "middle", "font-family": "Helvetica, Arial, sans-serif", "font-size": "16", fill: "#4caf50" do %>Marketplace<% end %>
<% end %>
EOF

cat <<EOF > app/views/shared/_header.html.erb
<%= tag.header role: "banner" do %>
  <%= render partial: "brgen_marketplace_logo/logo" %>
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
<% content_for :title, t("brgen_marketplace.home_title") %>
<% content_for :description, t("brgen_marketplace.home_description") %>
<% content_for :keywords, t("brgen_marketplace.home_keywords", default: "brgen marketplace, e-commerce, products") %>
<% content_for :schema do %>
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "WebPage",
    "name": "<%= t('brgen_marketplace.home_title') %>",
    "description": "<%= t('brgen_marketplace.home_description') %>",
    "url": "<%= request.original_url %>",
    "publisher": {
      "@type": "Organization",
      "name": "Brgen Marketplace",
      "logo": {
        "@type": "ImageObject",
        "url": "<%= image_url('brgen_marketplace_logo.svg') %>"
      }
    }
  }
  </script>
<% end %>
<%= render "shared/header" %>
<%= tag.main role: "main" do %>
  <%= tag.section aria-labelledby: "post-heading" do %>
    <%= tag.h1 t("brgen_marketplace.post_title"), id: "post-heading" %>
    <%= tag.div data: { turbo_frame: "notices" } do %>
      <%= render "shared/notices" %>
    <% end %>
    <%= render partial: "posts/form", locals: { post: Post.new } %>
  <% end %>
  <%= render partial: "shared/search", locals: { model: "Product", field: "name" } %>
  <%= tag.section aria-labelledby: "products-heading" do %>
    <%= tag.h2 t("brgen_marketplace.products_title"), id: "products-heading" %>
    <%= link_to t("brgen_marketplace.new_product"), new_product_path, class: "button", "aria-label": t("brgen_marketplace.new_product") if current_user %>
    <%= turbo_frame_tag "products" data: { controller: "infinite-scroll" } do %>
      <% @products.each do |product| %>
        <%= render partial: "products/card", locals: { product: product } %>
      <% end %>
      <%= tag.div id: "sentinel", class: "hidden", data: { reflex: "ProductsInfiniteScroll#load_more", next_page: @pagy.next || 2 } %>
    <% end %>
    <%= tag.button t("brgen_marketplace.load_more"), id: "load-more", data: { reflex: "click->ProductsInfiniteScroll#load_more", "next-page": @pagy.next || 2, "reflex-root": "#load-more" }, class: @pagy&.next ? "" : "hidden", "aria-label": t("brgen_marketplace.load_more") %>
  <% end %>
  <%= tag.section aria-labelledby: "posts-heading" do %>
    <%= tag.h2 t("brgen_marketplace.posts_title"), id: "posts-heading" %>
    <%= turbo_frame_tag "posts" data: { controller: "infinite-scroll" } do %>
      <% @posts.each do |post| %>
        <%= render partial: "posts/card", locals: { post: post } %>
      <% end %>
      <%= tag.div id: "sentinel", class: "hidden", data: { reflex: "PostsInfiniteScroll#load_more", next_page: @pagy.next || 2 } %>
    <% end %>
    <%= tag.button t("brgen_marketplace.load_more"), id: "load-more", data: { reflex: "click->PostsInfiniteScroll#load_more", "next-page": @pagy.next || 2, "reflex-root": "#load-more" }, class: @pagy&.next ? "" : "hidden", "aria-label": t("brgen_marketplace.load_more") %>
  <% end %>
  <%= render partial: "shared/chat" %>
<% end %>
<%= render "shared/footer" %>
EOF

cat <<EOF > app/views/products/index.html.erb
<% content_for :title, t("brgen_marketplace.products_title") %>
<% content_for :description, t("brgen_marketplace.products_description") %>
<% content_for :keywords, t("brgen_marketplace.products_keywords", default: "brgen marketplace, products, e-commerce") %>
<% content_for :schema do %>
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "WebPage",
    "name": "<%= t('brgen_marketplace.products_title') %>",
    "description": "<%= t('brgen_marketplace.products_description') %>",
    "url": "<%= request.original_url %>",
    "hasPart": [
      <% @products.each do |product| %>
      {
        "@type": "Product",
        "name": "<%= product.name %>",
        "description": "<%= product.description&.truncate(160) %>",
        "offers": {
          "@type": "Offer",
          "price": "<%= product.price %>",
          "priceCurrency": "NOK"
        }
      }<%= "," unless product == @products.last %>
      <% end %>
    ]
  }
  </script>
<% end %>
<%= render "shared/header" %>
<%= tag.main role: "main" do %>
  <%= tag.section aria-labelledby: "products-heading" do %>
    <%= tag.h1 t("brgen_marketplace.products_title"), id: "products-heading" %>
    <%= tag.div data: { turbo_frame: "notices" } do %>
      <%= render "shared/notices" %>
    <% end %>
    <%= link_to t("brgen_marketplace.new_product"), new_product_path, class: "button", "aria-label": t("brgen_marketplace.new_product") if current_user %>
    <%= turbo_frame_tag "products" data: { controller: "infinite-scroll" } do %>
      <% @products.each do |product| %>
        <%= render partial: "products/card", locals: { product: product } %>
      <% end %>
      <%= tag.div id: "sentinel", class: "hidden", data: { reflex: "ProductsInfiniteScroll#load_more", next_page: @pagy.next || 2 } %>
    <% end %>
    <%= tag.button t("brgen_marketplace.load_more"), id: "load-more", data: { reflex: "click->ProductsInfiniteScroll#load_more", "next-page": @pagy.next || 2, "reflex-root": "#load-more" }, class: @pagy&.next ? "" : "hidden", "aria-label": t("brgen_marketplace.load_more") %>
  <% end %>
  <%= render partial: "shared/search", locals: { model: "Product", field: "name" } %>
<% end %>
<%= render "shared/footer" %>
EOF

cat <<EOF > app/views/products/_card.html.erb
<%= turbo_frame_tag dom_id(product) do %>
  <%= tag.article class: "post-card", id: dom_id(product), role: "article" do %>
    <%= tag.div class: "post-header" do %>
      <%= tag.span t("brgen_marketplace.posted_by", user: product.user.email) %>
      <%= tag.span product.created_at.strftime("%Y-%m-%d %H:%M") %>
    <% end %>
    <%= tag.h2 product.name %>
    <%= tag.p product.description %>
    <%= tag.p t("brgen_marketplace.product_price", price: number_to_currency(product.price)) %>
    <% if product.photos.attached? %>
      <% product.photos.each do |photo| %>
        <%= image_tag photo, style: "max-width: 200px;", alt: t("brgen_marketplace.product_photo", name: product.name) %>
      <% end %>
    <% end %>
    <%= render partial: "shared/vote", locals: { votable: product } %>
    <%= tag.p class: "post-actions" do %>
      <%= link_to t("brgen_marketplace.view_product"), product_path(product), "aria-label": t("brgen_marketplace.view_product") %>
      <%= link_to t("brgen_marketplace.edit_product"), edit_product_path(product), "aria-label": t("brgen_marketplace.edit_product") if product.user == current_user || current_user&.admin? %>
      <%= button_to t("brgen_marketplace.delete_product"), product_path(product), method: :delete, data: { turbo_confirm: t("brgen_marketplace.confirm_delete") }, form: { data: { turbo_frame: "_top" } }, "aria-label": t("brgen_marketplace.delete_product") if product.user == current_user || current_user&.admin? %>
    <% end %>
  <% end %>
<% end %>
EOF

cat <<EOF > app/views/products/_form.html.erb
<%= form_with model: product, local: true, data: { controller: "character-counter form-validation", turbo: true } do |form| %>
  <%= tag.div data: { turbo_frame: "notices" } do %>
    <%= render "shared/notices" %>
  <% end %>
  <% if product.errors.any? %>
    <%= tag.div role: "alert" do %>
      <%= tag.p t("brgen_marketplace.errors", count: product.errors.count) %>
      <%= tag.ul do %>
        <% product.errors.full_messages.each do |msg| %>
          <%= tag.li msg %>
        <% end %>
      <% end %>
    <% end %>
  <% end %>
  <%= tag.fieldset do %>
    <%= form.label :name, t("brgen_marketplace.product_name"), "aria-required": true %>
    <%= form.text_field :name, required: true, data: { "form-validation-target": "input", action: "input->form-validation#validate" }, title: t("brgen_marketplace.product_name_help") %>
    <%= tag.span class: "error-message" data: { "form-validation-target": "error", for: "product_name" } %>
  <% end %>
  <%= tag.fieldset do %>
    <%= form.label :price, t("brgen_marketplace.product_price"), "aria-required": true %>
    <%= form.number_field :price, required: true, step: 0.01, data: { "form-validation-target": "input", action: "input->form-validation#validate" }, title: t("brgen_marketplace.product_price_help") %>
    <%= tag.span class: "error-message" data: { "form-validation-target": "error", for: "product_price" } %>
  <% end %>
  <%= tag.fieldset do %>
    <%= form.label :description, t("brgen_marketplace.product_description"), "aria-required": true %>
    <%= form.text_area :description, required: true, data: { "character-counter-target": "input", "textarea-autogrow-target": "input", "form-validation-target": "input", action: "input->character-counter#count input->textarea-autogrow#resize input->form-validation#validate" }, title: t("brgen_marketplace.product_description_help") %>
    <%= tag.span data: { "character-counter-target": "count" } %>
    <%= tag.span class: "error-message" data: { "form-validation-target": "error", for: "product_description" } %>
  <% end %>
  <%= tag.fieldset do %>
    <%= form.label :photos, t("brgen_marketplace.product_photos") %>
    <%= form.file_field :photos, multiple: true, accept: "image/*", data: { controller: "file-preview", "file-preview-target": "input" } %>
    <% if product.photos.attached? %>
      <% product.photos.each do |photo| %>
        <%= image_tag photo, style: "max-width: 200px;", alt: t("brgen_marketplace.product_photo", name: product.name) %>
      <% end %>
    <% end %>
    <%= tag.div data: { "file-preview-target": "preview" }, style: "display: none;" %>
  <% end %>
  <%= form.submit t("brgen_marketplace.#{product.persisted? ? 'update' : 'create'}_product"), data: { turbo_submits_with: t("brgen_marketplace.#{product.persisted? ? 'updating' : 'creating'}_product") } %>
<% end %>
EOF

cat <<EOF > app/views/products/new.html.erb
<% content_for :title, t("brgen_marketplace.new_product_title") %>
<% content_for :description, t("brgen_marketplace.new_product_description") %>
<% content_for :keywords, t("brgen_marketplace.new_product_keywords", default: "add product, brgen marketplace, e-commerce") %>
<% content_for :schema do %>
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "WebPage",
    "name": "<%= t('brgen_marketplace.new_product_title') %>",
    "description": "<%= t('brgen_marketplace.new_product_description') %>",
    "url": "<%= request.original_url %>"
  }
  </script>
<% end %>
<%= render "shared/header" %>
<%= tag.main role: "main" do %>
  <%= tag.section aria-labelledby: "new-product-heading" do %>
    <%= tag.h1 t("brgen_marketplace.new_product_title"), id: "new-product-heading" %>
    <%= render partial: "products/form", locals: { product: @product } %>
  <% end %>
<% end %>
<%= render "shared/footer" %>
EOF

cat <<EOF > app/views/products/edit.html.erb
<% content_for :title, t("brgen_marketplace.edit_product_title") %>
<% content_for :description, t("brgen_marketplace.edit_product_description") %>
<% content_for :keywords, t("brgen_marketplace.edit_product_keywords", default: "edit product, brgen marketplace, e-commerce") %>
<% content_for :schema do %>
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "WebPage",
    "name": "<%= t('brgen_marketplace.edit_product_title') %>",
    "description": "<%= t('brgen_marketplace.edit_product_description') %>",
    "url": "<%= request.original_url %>"
  }
  </script>
<% end %>
<%= render "shared/header" %>
<%= tag.main role: "main" do %>
  <%= tag.section aria-labelledby: "edit-product-heading" do %>
    <%= tag.h1 t("brgen_marketplace.edit_product_title"), id: "edit-product-heading" %>
    <%= render partial: "products/form", locals: { product: @product } %>
  <% end %>
<% end %>
<%= render "shared/footer" %>
EOF

cat <<EOF > app/views/products/show.html.erb
<% content_for :title, @product.name %>
<% content_for :description, @product.description&.truncate(160) %>
<% content_for :keywords, t("brgen_marketplace.product_keywords", name: @product.name, default: "product, #{@product.name}, brgen marketplace, e-commerce") %>
<% content_for :schema do %>
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "Product",
    "name": "<%= @product.name %>",
    "description": "<%= @product.description&.truncate(160) %>",
    "offers": {
      "@type": "Offer",
      "price": "<%= @product.price %>",
      "priceCurrency": "NOK"
    }
  }
  </script>
<% end %>
<%= render "shared/header" %>
<%= tag.main role: "main" do %>
  <%= tag.section aria-labelledby: "product-heading" class: "post-card" do %>
    <%= tag.div data: { turbo_frame: "notices" } do %>
      <%= render "shared/notices" %>
    <% end %>
    <%= tag.h1 @product.name, id: "product-heading" %>
    <%= render partial: "products/card", locals: { product: @product } %>
  <% end %>
<% end %>
<%= render "shared/footer" %>
EOF

cat <<EOF > app/views/orders/index.html.erb
<% content_for :title, t("brgen_marketplace.orders_title") %>
<% content_for :description, t("brgen_marketplace.orders_description") %>
<% content_for :keywords, t("brgen_marketplace.orders_keywords", default: "brgen marketplace, orders, e-commerce") %>
<% content_for :schema do %>
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "WebPage",
    "name": "<%= t('brgen_marketplace.orders_title') %>",
    "description": "<%= t('brgen_marketplace.orders_description') %>",
    "url": "<%= request.original_url %>"
  }
  </script>
<% end %>
<%= render "shared/header" %>
<%= tag.main role: "main" do %>
  <%= tag.section aria-labelledby: "orders-heading" do %>
    <%= tag.h1 t("brgen_marketplace.orders_title"), id: "orders-heading" %>
    <%= tag.div data: { turbo_frame: "notices" } do %>
      <%= render "shared/notices" %>
    <% end %>
    <%= link_to t("brgen_marketplace.new_order"), new_order_path, class: "button", "aria-label": t("brgen_marketplace.new_order") %>
    <%= turbo_frame_tag "orders" data: { controller: "infinite-scroll" } do %>
      <% @orders.each do |order| %>
        <%= render partial: "orders/card", locals: { order: order } %>
      <% end %>
      <%= tag.div id: "sentinel", class: "hidden", data: { reflex: "OrdersInfiniteScroll#load_more", next_page: @pagy.next || 2 } %>
    <% end %>
    <%= tag.button t("brgen_marketplace.load_more"), id: "load-more", data: { reflex: "click->OrdersInfiniteScroll#load_more", "next-page": @pagy.next || 2, "reflex-root": "#load-more" }, class: @pagy&.next ? "" : "hidden", "aria-label": t("brgen_marketplace.load_more") %>
  <% end %>
<% end %>
<%= render "shared/footer" %>
EOF

cat <<EOF > app/views/orders/_card.html.erb
<%= turbo_frame_tag dom_id(order) do %>
  <%= tag.article class: "post-card", id: dom_id(order), role: "article" do %>
    <%= tag.div class: "post-header" do %>
      <%= tag.span t("brgen_marketplace.ordered_by", user: order.buyer.email) %>
      <%= tag.span order.created_at.strftime("%Y-%m-%d %H:%M") %>
    <% end %>
    <%= tag.h2 order.product.name %>
    <%= tag.p t("brgen_marketplace.order_status", status: order.status) %>
    <%= render partial: "shared/vote", locals: { votable: order } %>
    <%= tag.p class: "post-actions" do %>
      <%= link_to t("brgen_marketplace.view_order"), order_path(order), "aria-label": t("brgen_marketplace.view_order") %>
      <%= link_to t("brgen_marketplace.edit_order"), edit_order_path(order), "aria-label": t("brgen_marketplace.edit_order") if order.buyer == current_user || current_user&.admin? %>
      <%= button_to t("brgen_marketplace.delete_order"), order_path(order), method: :delete, data: { turbo_confirm: t("brgen_marketplace.confirm_delete") }, form: { data: { turbo_frame: "_top" } }, "aria-label": t("brgen_marketplace.delete_order") if order.buyer == current_user || current_user&.admin? %>
    <% end %>
  <% end %>
<% end %>
EOF

cat <<EOF > app/views/orders/_form.html.erb
<%= form_with model: order, local: true, data: { controller: "form-validation", turbo: true } do |form| %>
  <%= tag.div data: { turbo_frame: "notices" } do %>
    <%= render "shared/notices" %>
  <% end %>
  <% if order.errors.any? %>
    <%= tag.div role: "alert" do %>
      <%= tag.p t("brgen_marketplace.errors", count: order.errors.count) %>
      <%= tag.ul do %>
        <% order.errors.full_messages.each do |msg| %>
          <%= tag.li msg %>
        <% end %>
      <% end %>
    <% end %>
  <% end %>
  <%= tag.fieldset do %>
    <%= form.label :product_id, t("brgen_marketplace.order_product"), "aria-required": true %>
    <%= form.collection_select :product_id, Product.all, :id, :name, { prompt: t("brgen_marketplace.product_prompt") }, required: true %>
    <%= tag.span class: "error-message" data: { "form-validation-target": "error", for: "order_product_id" } %>
  <% end %>
  <%= tag.fieldset do %>
    <%= form.label :status, t("brgen_marketplace.order_status"), "aria-required": true %>
    <%= form.select :status, ["pending", "shipped", "delivered"], { prompt: t("brgen_marketplace.status_prompt"), selected: order.status }, required: true %>
    <%= tag.span class: "error-message" data: { "form-validation-target": "error", for: "order_status" } %>
  <% end %>
  <%= form.submit t("brgen_marketplace.#{order.persisted? ? 'update' : 'create'}_order"), data: { turbo_submits_with: t("brgen_marketplace.#{order.persisted? ? 'updating' : 'creating'}_order") } %>
<% end %>
EOF

cat <<EOF > app/views/orders/new.html.erb
<% content_for :title, t("brgen_marketplace.new_order_title") %>
<% content_for :description, t("brgen_marketplace.new_order_description") %>
<% content_for :keywords, t("brgen_marketplace.new_order_keywords", default: "add order, brgen marketplace, e-commerce") %>
<% content_for :schema do %>
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "WebPage",
    "name": "<%= t('brgen_marketplace.new_order_title') %>",
    "description": "<%= t('brgen_marketplace.new_order_description') %>",
    "url": "<%= request.original_url %>"
  }
  </script>
<% end %>
<%= render "shared/header" %>
<%= tag.main role: "main" do %>
  <%= tag.section aria-labelledby: "new-order-heading" do %>
    <%= tag.h1 t("brgen_marketplace.new_order_title"), id: "new-order-heading" %>
    <%= render partial: "orders/form", locals: { order: @order } %>
  <% end %>
<% end %>
<%= render "shared/footer" %>
EOF

cat <<EOF > app/views/orders/edit.html.erb
<% content_for :title, t("brgen_marketplace.edit_order_title") %>
<% content_for :description, t("brgen_marketplace.edit_order_description") %>
<% content_for :keywords, t("brgen_marketplace.edit_order_keywords", default: "edit order, brgen marketplace, e-commerce") %>
<% content_for :schema do %>
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "WebPage",
    "name": "<%= t('brgen_marketplace.edit_order_title') %>",
    "description": "<%= t('brgen_marketplace.edit_order_description') %>",
    "url": "<%= request.original_url %>"
  }
  </script>
<% end %>
<%= render "shared/header" %>
<%= tag.main role: "main" do %>
  <%= tag.section aria-labelledby: "edit-order-heading" do %>
    <%= tag.h1 t("brgen_marketplace.edit_order_title"), id: "edit-order-heading" %>
    <%= render partial: "orders/form", locals: { order: @order } %>
  <% end %>
<% end %>
<%= render "shared/footer" %>
EOF

cat <<EOF > app/views/orders/show.html.erb
<% content_for :title, t("brgen_marketplace.order_title", product: @order.product.name) %>
<% content_for :description, t("brgen_marketplace.order_description", product: @order.product.name) %>
<% content_for :keywords, t("brgen_marketplace.order_keywords", product: @order.product.name, default: "order, #{@order.product.name}, brgen marketplace, e-commerce") %>
<% content_for :schema do %>
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "Order",
    "orderNumber": "<%= @order.id %>",
    "orderStatus": "<%= @order.status %>",
    "orderedItem": {
      "@type": "Product",
      "name": "<%= @order.product.name %>"
    }
  }
  </script>
<% end %>
<%= render "shared/header" %>
<%= tag.main role: "main" do %>
  <%= tag.section aria-labelledby: "order-heading" class: "post-card" do %>
    <%= tag.div data: { turbo_frame: "notices" } do %>
      <%= render "shared/notices" %>
    <% end %>
    <%= tag.h1 t("brgen_marketplace.order_title", product: @order.product.name), id: "order-heading" %>
    <%= render partial: "orders/card", locals: { order: @order } %>
  <% end %>
<% end %>
<%= render "shared/footer" %>
EOF

generate_turbo_views "products" "product"
generate_turbo_views "orders" "order"

# Enhanced models with SEO, caching, and marketplace features
cat <<EOF > app/models/product.rb
class Product < ApplicationRecord
  extend FriendlyId
  include Cacheable
  include SitemapGenerator
  
  acts_as_tenant(:tenant, class_name: 'City')
  acts_as_votable
  
  friendly_id :name, use: [:slugged, :scoped], scope: :tenant
  
  belongs_to :user
  belongs_to :tenant, class_name: 'City', optional: true
  has_many :orders, dependent: :destroy
  has_many :product_reviews, dependent: :destroy
  has_many :product_favorites, dependent: :destroy
  has_many :product_questions, dependent: :destroy
  has_many :karma_actions, as: :target, dependent: :destroy
  has_many_attached :photos
  
  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :price, presence: true, numericality: { greater_than: 0 }
  validates :description, presence: true, length: { minimum: 10, maximum: 1000 }
  validates :category, presence: true
  validates :condition, presence: true, inclusion: { in: %w[new like_new good fair poor] }
  validates :karma_score, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :view_count, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  
  scope :available, -> { where(sold: false) }
  scope :sold_items, -> { where(sold: true) }
  scope :popular, -> { order(karma_score: :desc, view_count: :desc) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_category, ->(category) { where(category: category) }
  scope :by_condition, ->(condition) { where(condition: condition) }
  scope :trending, -> { where('view_count > ? AND created_at > ?', 20, 1.week.ago).order(:view_count) }
  
  before_save :calculate_karma_score
  after_commit :update_sitemap, if: :should_update_sitemap?
  
  CATEGORIES = %w[
    electronics clothing home_garden books_media sports_outdoors
    automotive toys_games health_beauty tools_diy furniture
    collectibles jewelry_accessories baby_kids other
  ].freeze
  
  CONDITIONS = %w[new like_new good fair poor].freeze
  
  def should_regenerate_slug?
    name_changed? || slug.blank?
  end
  
  def average_rating
    product_reviews.average(:rating)&.round(1) || 0
  end
  
  def favorites_count
    product_favorites.count
  end
  
  def trending?
    view_count > 20 && created_at > 1.week.ago
  end
  
  def condition_text
    condition.humanize
  end
  
  def category_text
    category.humanize.titleize
  end
  
  def primary_photo
    photos.attached? ? photos.first : nil
  end
  
  def formatted_price
    "#{price.to_i} NOK"
  end
  
  private
  
  def calculate_karma_score
    self.karma_score = (get_upvotes.size * 3) - (get_downvotes.size * 1) + 
                       (product_favorites.count * 2) + 
                       (product_reviews.count * 1) + 
                       (view_count / 10)
    self.karma_score += 5 if sold? # Bonus for successful sale
  end
  
  def should_update_sitemap?
    saved_change_to_name? || saved_change_to_slug? || saved_change_to_sold?
  end
  
  def update_sitemap
    SitemapRegenerateJob.perform_later unless sold?
  end
end
EOF

cat <<EOF > app/models/marketplace_karma.rb
class MarketplaceKarma < ApplicationRecord
  belongs_to :user
  
  validates :product_karma, :review_karma, :question_karma, :sale_karma, :total_karma, 
            numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :level, numericality: { greater_than_or_equal_to: 1 }, allow_nil: true
  
  before_save :calculate_level
  
  def calculate_level
    self.level = case total_karma || 0
                 when 0..24 then 1
                 when 25..74 then 2
                 when 75..149 then 3
                 when 150..299 then 4
                 when 300..499 then 5
                 else 6
                 end
  end
  
  def level_name
    case level
    when 1 then "New Seller"
    when 2 then "Casual Trader"
    when 3 then "Active Seller"
    when 4 then "Marketplace Pro"
    when 5 then "Trusted Vendor"
    else "Marketplace Master"
    end
  end
  
  def level_badge_color
    case level
    when 1 then "bronze"
    when 2 then "silver"  
    when 3 then "gold"
    when 4 then "platinum"
    when 5 then "diamond"
    else "master"
    end
  end
  
  def next_level_threshold
    case level
    when 1 then 25
    when 2 then 75
    when 3 then 150
    when 4 then 300
    when 5 then 500
    else nil
    end
  end
  
  def progress_to_next_level
    return 100 unless next_level_threshold
    
    current_level_min = case level
                       when 1 then 0
                       when 2 then 25
                       when 3 then 75
                       when 4 then 150
                       when 5 then 300
                       else 500
                       end
    
    ((total_karma - current_level_min).to_f / (next_level_threshold - current_level_min) * 100).round
  end
end
EOF

commit "Brgen Marketplace setup complete: E-commerce platform with live search, infinite scroll, and anonymous features"

log "Brgen Marketplace setup complete. Run 'bin/falcon-host' with PORT set to start on OpenBSD."

# Change Log:
# - Aligned with master.json v6.5.0: Two-space indents, double quotes, heredocs, Strunk & White comments.
# - Used Rails 8 conventions, Hotwire, Turbo Streams, Stimulus Reflex, I18n, and Falcon.
# - Leveraged bin/rails generate scaffold for Products and Orders to streamline CRUD setup.
# - Extracted header, footer, search, and model-specific forms/cards into partials for DRY views.
# - Included live search, infinite scroll, and anonymous posting/chat via shared utilities.
# - Ensured NNG principles, SEO, schema data, and minimal flat design compliance.
# - Finalized for unprivileged user on OpenBSD 7.5.