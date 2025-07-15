#!/usr/bin/env zsh
# Brgen Playlist: Music playlist sharing platform with cognitive framework implementation
# Master.json v10.7.0 compliance with zero-trust security and intelligent music curation

set -e
setopt extended_glob null_glob

# === COGNITIVE FRAMEWORK CONFIGURATION ===
APP_NAME="brgen_playlist"
BASE_DIR="/home/dev/rails"
BRGEN_IP="46.23.95.45"

# Source enhanced shared functionality
source "../../__shared_enhanced.sh"

# === PLAYLIST-SPECIFIC CONFIGURATION ===
generate_application_code() {
  phase_transition "playlist_code_generation" "Creating intelligent music playlist platform features"
  
  # Generate models with cognitive constraints (7 concepts max)
  bin/rails generate model Playlist name:string description:text user:references visibility:string
  bin/rails generate model Song title:string artist:string album:string duration:integer
  bin/rails generate model PlaylistSong playlist:references song:references position:integer
  bin/rails generate model PlaylistFollow user:references playlist:references
  bin/rails generate model MusicGenre name:string description:text
  bin/rails generate model SongGenre song:references music_genre:references
  bin/rails generate model PlaylistLike user:references playlist:references
  
  # Database migrations
  bin/rails db:migrate
  
  # Enhanced playlist implementation with cognitive load management
  log "Playlist application code generation completed" "INFO"
}

# Override main to use enhanced installation
main() {
  log "Starting Brgen Playlist installation with cognitive framework" "INFO"
  
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
    generate_application_code  # This will use our Playlist-specific implementation
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

bin/rails generate scaffold Playlist name:string description:text user:references tracks:text
bin/rails generate scaffold Comment playlist:references user:references content:text

cat <<EOF > app/reflexes/playlists_infinite_scroll_reflex.rb
class PlaylistsInfiniteScrollReflex < InfiniteScrollReflex
  def load_more
    @pagy, @collection = pagy(Playlist.all.order(created_at: :desc), page: page)
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

cat <<EOF > app/controllers/playlists_controller.rb
class PlaylistsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_playlist, only: [:show, :edit, :update, :destroy]

  def index
    @pagy, @playlists = pagy(Playlist.all.order(created_at: :desc)) unless @stimulus_reflex
  end

  def show
  end

  def new
    @playlist = Playlist.new
  end

  def create
    @playlist = Playlist.new(playlist_params)
    @playlist.user = current_user
    if @playlist.save
      respond_to do |format|
        format.html { redirect_to playlists_path, notice: t("brgen_playlist.playlist_created") }
        format.turbo_stream
      end
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @playlist.update(playlist_params)
      respond_to do |format|
        format.html { redirect_to playlists_path, notice: t("brgen_playlist.playlist_updated") }
        format.turbo_stream
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @playlist.destroy
    respond_to do |format|
      format.html { redirect_to playlists_path, notice: t("brgen_playlist.playlist_deleted") }
      format.turbo_stream
    end
  end

  private

  def set_playlist
    @playlist = Playlist.find(params[:id])
    redirect_to playlists_path, alert: t("brgen_playlist.not_authorized") unless @playlist.user == current_user || current_user&.admin?
  end

  def playlist_params
    params.require(:playlist).permit(:name, :description, :tracks)
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
        format.html { redirect_to comments_path, notice: t("brgen_playlist.comment_created") }
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
        format.html { redirect_to comments_path, notice: t("brgen_playlist.comment_updated") }
        format.turbo_stream
      end
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @comment.destroy
    respond_to do |format|
      format.html { redirect_to comments_path, notice: t("brgen_playlist.comment_deleted") }
      format.turbo_stream
    end
  end

  private

  def set_comment
    @comment = Comment.find(params[:id])
    redirect_to comments_path, alert: t("brgen_playlist.not_authorized") unless @comment.user == current_user || current_user&.admin?
  end

  def comment_params
    params.require(:comment).permit(:playlist_id, :content)
  end
end
EOF

cat <<EOF > app/controllers/home_controller.rb
class HomeController < ApplicationController
  def index
    @pagy, @posts = pagy(Post.all.order(created_at: :desc), items: 10) unless @stimulus_reflex
    @playlists = Playlist.all.order(created_at: :desc).limit(5)
  end
end
EOF

mkdir -p app/views/brgen_playlist_logo

cat <<EOF > app/views/brgen_playlist_logo/_logo.html.erb
<%= tag.svg xmlns: "http://www.w3.org/2000/svg", viewBox: "0 0 100 50", role: "img", class: "logo", "aria-label": t("brgen_playlist.logo_alt") do %>
  <%= tag.title t("brgen_playlist.logo_title", default: "Brgen Playlist Logo") %>
  <%= tag.text x: "50", y: "30", "text-anchor": "middle", "font-family": "Helvetica, Arial, sans-serif", "font-size": "16", fill: "#ff9800" do %>Playlist<% end %>
<% end %>
EOF

cat <<EOF > app/views/shared/_header.html.erb
<%= tag.header role: "banner" do %>
  <%= render partial: "brgen_playlist_logo/logo" %>
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
<% content_for :title, t("brgen_playlist.home_title") %>
<% content_for :description, t("brgen_playlist.home_description") %>
<% content_for :keywords, t("brgen_playlist.home_keywords", default: "brgen playlist, music, sharing") %>
<% content_for :schema do %>
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "WebPage",
    "name": "<%= t('brgen_playlist.home_title') %>",
    "description": "<%= t('brgen_playlist.home_description') %>",
    "url": "<%= request.original_url %>",
    "publisher": {
      "@type": "Organization",
      "name": "Brgen Playlist",
      "logo": {
        "@type": "ImageObject",
        "url": "<%= image_url('brgen_playlist_logo.svg') %>"
      }
    }
  }
  </script>
<% end %>
<%= render "shared/header" %>
<%= tag.main role: "main" do %>
  <%= tag.section aria-labelledby: "post-heading" do %>
    <%= tag.h1 t("brgen_playlist.post_title"), id: "post-heading" %>
    <%= tag.div data: { turbo_frame: "notices" } do %>
      <%= render "shared/notices" %>
    <% end %>
    <%= render partial: "posts/form", locals: { post: Post.new } %>
  <% end %>
  <%= render partial: "shared/search", locals: { model: "Playlist", field: "name" } %>
  <%= tag.section aria-labelledby: "playlists-heading" do %>
    <%= tag.h2 t("brgen_playlist.playlists_title"), id: "playlists-heading" %>
    <%= link_to t("brgen_playlist.new_playlist"), new_playlist_path, class: "button", "aria-label": t("brgen_playlist.new_playlist") if current_user %>
    <%= turbo_frame_tag "playlists" data: { controller: "infinite-scroll" } do %>
      <% @playlists.each do |playlist| %>
        <%= render partial: "playlists/card", locals: { playlist: playlist } %>
      <% end %>
      <%= tag.div id: "sentinel", class: "hidden", data: { reflex: "PlaylistsInfiniteScroll#load_more", next_page: @pagy.next || 2 } %>
    <% end %>
    <%= tag.button t("brgen_playlist.load_more"), id: "load-more", data: { reflex: "click->PlaylistsInfiniteScroll#load_more", "next-page": @pagy.next || 2, "reflex-root": "#load-more" }, class: @pagy&.next ? "" : "hidden", "aria-label": t("brgen_playlist.load_more") %>
  <% end %>
  <%= tag.section aria-labelledby: "posts-heading" do %>
    <%= tag.h2 t("brgen_playlist.posts_title"), id: "posts-heading" %>
    <%= turbo_frame_tag "posts" data: { controller: "infinite-scroll" } do %>
      <% @posts.each do |post| %>
        <%= render partial: "posts/card", locals: { post: post } %>
      <% end %>
      <%= tag.div id: "sentinel", class: "hidden", data: { reflex: "PostsInfiniteScroll#load_more", next_page: @pagy.next || 2 } %>
    <% end %>
    <%= tag.button t("brgen_playlist.load_more"), id: "load-more", data: { reflex: "click->PostsInfiniteScroll#load_more", "next-page": @pagy.next || 2, "reflex-root": "#load-more" }, class: @pagy&.next ? "" : "hidden", "aria-label": t("brgen_playlist.load_more") %>
  <% end %>
  <%= render partial: "shared/chat" %>
<% end %>
<%= render "shared/footer" %>
EOF

cat <<EOF > app/views/playlists/index.html.erb
<% content_for :title, t("brgen_playlist.playlists_title") %>
<% content_for :description, t("brgen_playlist.playlists_description") %>
<% content_for :keywords, t("brgen_playlist.playlists_keywords", default: "brgen playlist, music, sharing") %>
<% content_for :schema do %>
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "WebPage",
    "name": "<%= t('brgen_playlist.playlists_title') %>",
    "description": "<%= t('brgen_playlist.playlists_description') %>",
    "url": "<%= request.original_url %>",
    "hasPart": [
      <% @playlists.each do |playlist| %>
      {
        "@type": "MusicPlaylist",
        "name": "<%= playlist.name %>",
        "description": "<%= playlist.description&.truncate(160) %>"
      }<%= "," unless playlist == @playlists.last %>
      <% end %>
    ]
  }
  </script>
<% end %>
<%= render "shared/header" %>
<%= tag.main role: "main" do %>
  <%= tag.section aria-labelledby: "playlists-heading" do %>
    <%= tag.h1 t("brgen_playlist.playlists_title"), id: "playlists-heading" %>
    <%= tag.div data: { turbo_frame: "notices" } do %>
      <%= render "shared/notices" %>
    <% end %>
    <%= link_to t("brgen_playlist.new_playlist"), new_playlist_path, class: "button", "aria-label": t("brgen_playlist.new_playlist") if current_user %>
    <%= turbo_frame_tag "playlists" data: { controller: "infinite-scroll" } do %>
      <% @playlists.each do |playlist| %>
        <%= render partial: "playlists/card", locals: { playlist: playlist } %>
      <% end %>
      <%= tag.div id: "sentinel", class: "hidden", data: { reflex: "PlaylistsInfiniteScroll#load_more", next_page: @pagy.next || 2 } %>
    <% end %>
    <%= tag.button t("brgen_playlist.load_more"), id: "load-more", data: { reflex: "click->PlaylistsInfiniteScroll#load_more", "next-page": @pagy.next || 2, "reflex-root": "#load-more" }, class: @pagy&.next ? "" : "hidden", "aria-label": t("brgen_playlist.load_more") %>
  <% end %>
  <%= render partial: "shared/search", locals: { model: "Playlist", field: "name" } %>
<% end %>
<%= render "shared/footer" %>
EOF

cat <<EOF > app/views/playlists/_card.html.erb
<%= turbo_frame_tag dom_id(playlist) do %>
  <%= tag.article class: "post-card", id: dom_id(playlist), role: "article" do %>
    <%= tag.div class: "post-header" do %>
      <%= tag.span t("brgen_playlist.posted_by", user: playlist.user.email) %>
      <%= tag.span playlist.created_at.strftime("%Y-%m-%d %H:%M") %>
    <% end %>
    <%= tag.h2 playlist.name %>
    <%= tag.p playlist.description %>
    <%= tag.p t("brgen_playlist.playlist_tracks", tracks: playlist.tracks) %>
    <%= render partial: "shared/vote", locals: { votable: playlist } %>
    <%= tag.p class: "post-actions" do %>
      <%= link_to t("brgen_playlist.view_playlist"), playlist_path(playlist), "aria-label": t("brgen_playlist.view_playlist") %>
      <%= link_to t("brgen_playlist.edit_playlist"), edit_playlist_path(playlist), "aria-label": t("brgen_playlist.edit_playlist") if playlist.user == current_user || current_user&.admin? %>
      <%= button_to t("brgen_playlist.delete_playlist"), playlist_path(playlist), method: :delete, data: { turbo_confirm: t("brgen_playlist.confirm_delete") }, form: { data: { turbo_frame: "_top" } }, "aria-label": t("brgen_playlist.delete_playlist") if playlist.user == current_user || current_user&.admin? %>
    <% end %>
  <% end %>
<% end %>
EOF

cat <<EOF > app/views/playlists/_form.html.erb
<%= form_with model: playlist, local: true, data: { controller: "character-counter form-validation", turbo: true } do |form| %>
  <%= tag.div data: { turbo_frame: "notices" } do %>
    <%= render "shared/notices" %>
  <% end %>
  <% if playlist.errors.any? %>
    <%= tag.div role: "alert" do %>
      <%= tag.p t("brgen_playlist.errors", count: playlist.errors.count) %>
      <%= tag.ul do %>
        <% playlist.errors.full_messages.each do |msg| %>
          <%= tag.li msg %>
        <% end %>
      <% end %>
    <% end %>
  <% end %>
  <%= tag.fieldset do %>
    <%= form.label :name, t("brgen_playlist.playlist_name"), "aria-required": true %>
    <%= form.text_field :name, required: true, data: { "form-validation-target": "input", action: "input->form-validation#validate" }, title: t("brgen_playlist.playlist_name_help") %>
    <%= tag.span class: "error-message" data: { "form-validation-target": "error", for: "playlist_name" } %>
  <% end %>
  <%= tag.fieldset do %>
    <%= form.label :description, t("brgen_playlist.playlist_description"), "aria-required": true %>
    <%= form.text_area :description, required: true, data: { "character-counter-target": "input", "textarea-autogrow-target": "input", "form-validation-target": "input", action: "input->character-counter#count input->textarea-autogrow#resize input->form-validation#validate" }, title: t("brgen_playlist.playlist_description_help") %>
    <%= tag.span data: { "character-counter-target": "count" } %>
    <%= tag.span class: "error-message" data: { "form-validation-target": "error", for: "playlist_description" } %>
  <% end %>
  <%= tag.fieldset do %>
    <%= form.label :tracks, t("brgen_playlist.playlist_tracks"), "aria-required": true %>
    <%= form.text_area :tracks, required: true, data: { "character-counter-target": "input", "textarea-autogrow-target": "input", "form-validation-target": "input", action: "input->character-counter#count input->textarea-autogrow#resize input->form-validation#validate" }, title: t("brgen_playlist.playlist_tracks_help") %>
    <%= tag.span data: { "character-counter-target": "count" } %>
    <%= tag.span class: "error-message" data: { "form-validation-target": "error", for: "playlist_tracks" } %>
  <% end %>
  <%= form.submit t("brgen_playlist.#{playlist.persisted? ? 'update' : 'create'}_playlist"), data: { turbo_submits_with: t("brgen_playlist.#{playlist.persisted? ? 'updating' : 'creating'}_playlist") } %>
<% end %>
EOF

cat <<EOF > app/views/playlists/new.html.erb
<% content_for :title, t("brgen_playlist.new_playlist_title") %>
<% content_for :description, t("brgen_playlist.new_playlist_description") %>
<% content_for :keywords, t("brgen_playlist.new_playlist_keywords", default: "add playlist, brgen playlist, music") %>
<% content_for :schema do %>
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "WebPage",
    "name": "<%= t('brgen_playlist.new_playlist_title') %>",
    "description": "<%= t('brgen_playlist.new_playlist_description') %>",
    "url": "<%= request.original_url %>"
  }
  </script>
<% end %>
<%= render "shared/header" %>
<%= tag.main role: "main" do %>
  <%= tag.section aria-labelledby: "new-playlist-heading" do %>
    <%= tag.h1 t("brgen_playlist.new_playlist_title"), id: "new-playlist-heading" %>
    <%= render partial: "playlists/form", locals: { playlist: @playlist } %>
  <% end %>
<% end %>
<%= render "shared/footer" %>
EOF

cat <<EOF > app/views/playlists/edit.html.erb
<% content_for :title, t("brgen_playlist.edit_playlist_title") %>
<% content_for :description, t("brgen_playlist.edit_playlist_description") %>
<% content_for :keywords, t("brgen_playlist.edit_playlist_keywords", default: "edit playlist, brgen playlist, music") %>
<% content_for :schema do %>
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "WebPage",
    "name": "<%= t('brgen_playlist.edit_playlist_title') %>",
    "description": "<%= t('brgen_playlist.edit_playlist_description') %>",
    "url": "<%= request.original_url %>"
  }
  </script>
<% end %>
<%= render "shared/header" %>
<%= tag.main role: "main" do %>
  <%= tag.section aria-labelledby: "edit-playlist-heading" do %>
    <%= tag.h1 t("brgen_playlist.edit_playlist_title"), id: "edit-playlist-heading" %>
    <%= render partial: "playlists/form", locals: { playlist: @playlist } %>
  <% end %>
<% end %>
<%= render "shared/footer" %>
EOF

cat <<EOF > app/views/playlists/show.html.erb
<% content_for :title, @playlist.name %>
<% content_for :description, @playlist.description&.truncate(160) %>
<% content_for :keywords, t("brgen_playlist.playlist_keywords", name: @playlist.name, default: "playlist, #{@playlist.name}, brgen playlist, music") %>
<% content_for :schema do %>
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "MusicPlaylist",
    "name": "<%= @playlist.name %>",
    "description": "<%= @playlist.description&.truncate(160) %>"
  }
  </script>
<% end %>
<%= render "shared/header" %>
<%= tag.main role: "main" do %>
  <%= tag.section aria-labelledby: "playlist-heading" class: "post-card" do %>
    <%= tag.div data: { turbo_frame: "notices" } do %>
      <%= render "shared/notices" %>
    <% end %>
    <%= tag.h1 @playlist.name, id: "playlist-heading" %>
    <%= render partial: "playlists/card", locals: { playlist: @playlist } %>
  <% end %>
<% end %>
<%= render "shared/footer" %>
EOF

cat <<EOF > app/views/comments/index.html.erb
<% content_for :title, t("brgen_playlist.comments_title") %>
<% content_for :description, t("brgen_playlist.comments_description") %>
<% content_for :keywords, t("brgen_playlist.comments_keywords", default: "brgen playlist, comments, music") %>
<% content_for :schema do %>
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "WebPage",
    "name": "<%= t('brgen_playlist.comments_title') %>",
    "description": "<%= t('brgen_playlist.comments_description') %>",
    "url": "<%= request.original_url %>"
  }
  </script>
<% end %>
<%= render "shared/header" %>
<%= tag.main role: "main" do %>
  <%= tag.section aria-labelledby: "comments-heading" do %>
    <%= tag.h1 t("brgen_playlist.comments_title"), id: "comments-heading" %>
    <%= tag.div data: { turbo_frame: "notices" } do %>
      <%= render "shared/notices" %>
    <% end %>
    <%= link_to t("brgen_playlist.new_comment"), new_comment_path, class: "button", "aria-label": t("brgen_playlist.new_comment") %>
    <%= turbo_frame_tag "comments" data: { controller: "infinite-scroll" } do %>
      <% @comments.each do |comment| %>
        <%= render partial: "comments/card", locals: { comment: comment } %>
      <% end %>
      <%= tag.div id: "sentinel", class: "hidden", data: { reflex: "CommentsInfiniteScroll#load_more", next_page: @pagy.next || 2 } %>
    <% end %>
    <%= tag.button t("brgen_playlist.load_more"), id: "load-more", data: { reflex: "click->CommentsInfiniteScroll#load_more", "next-page": @pagy.next || 2, "reflex-root": "#load-more" }, class: @pagy&.next ? "" : "hidden", "aria-label": t("brgen_playlist.load_more") %>
  <% end %>
<% end %>
<%= render "shared/footer" %>
EOF

cat <<EOF > app/views/comments/_card.html.erb
<%= turbo_frame_tag dom_id(comment) do %>
  <%= tag.article class: "post-card", id: dom_id(comment), role: "article" do %>
    <%= tag.div class: "post-header" do %>
      <%= tag.span t("brgen_playlist.posted_by", user: comment.user.email) %>
      <%= tag.span comment.created_at.strftime("%Y-%m-%d %H:%M") %>
    <% end %>
    <%= tag.h2 comment.playlist.name %>
    <%= tag.p comment.content %>
    <%= render partial: "shared/vote", locals: { votable: comment } %>
    <%= tag.p class: "post-actions" do %>
      <%= link_to t("brgen_playlist.view_comment"), comment_path(comment), "aria-label": t("brgen_playlist.view_comment") %>
      <%= link_to t("brgen_playlist.edit_comment"), edit_comment_path(comment), "aria-label": t("brgen_playlist.edit_comment") if comment.user == current_user || current_user&.admin? %>
      <%= button_to t("brgen_playlist.delete_comment"), comment_path(comment), method: :delete, data: { turbo_confirm: t("brgen_playlist.confirm_delete") }, form: { data: { turbo_frame: "_top" } }, "aria-label": t("brgen_playlist.delete_comment") if comment.user == current_user || current_user&.admin? %>
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
      <%= tag.p t("brgen_playlist.errors", count: comment.errors.count) %>
      <%= tag.ul do %>
        <% comment.errors.full_messages.each do |msg| %>
          <%= tag.li msg %>
        <% end %>
      <% end %>
    <% end %>
  <% end %>
  <%= tag.fieldset do %>
    <%= form.label :playlist_id, t("brgen_playlist.comment_playlist"), "aria-required": true %>
    <%= form.collection_select :playlist_id, Playlist.all, :id, :name, { prompt: t("brgen_playlist.playlist_prompt") }, required: true %>
    <%= tag.span class: "error-message" data: { "form-validation-target": "error", for: "comment_playlist_id" } %>
  <% end %>
  <%= tag.fieldset do %>
    <%= form.label :content, t("brgen_playlist.comment_content"), "aria-required": true %>
    <%= form.text_area :content, required: true, data: { "character-counter-target": "input", "textarea-autogrow-target": "input", "form-validation-target": "input", action: "input->character-counter#count input->textarea-autogrow#resize input->form-validation#validate" }, title: t("brgen_playlist.comment_content_help") %>
    <%= tag.span data: { "character-counter-target": "count" } %>
    <%= tag.span class: "error-message" data: { "form-validation-target": "error", for: "comment_content" } %>
  <% end %>
  <%= form.submit t("brgen_playlist.#{comment.persisted? ? 'update' : 'create'}_comment"), data: { turbo_submits_with: t("brgen_playlist.#{comment.persisted? ? 'updating' : 'creating'}_comment") } %>
<% end %>
EOF

cat <<EOF > app/views/comments/new.html.erb
<% content_for :title, t("brgen_playlist.new_comment_title") %>
<% content_for :description, t("brgen_playlist.new_comment_description") %>
<% content_for :keywords, t("brgen_playlist.new_comment_keywords", default: "add comment, brgen playlist, music") %>
<% content_for :schema do %>
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "WebPage",
    "name": "<%= t('brgen_playlist.new_comment_title') %>",
    "description": "<%= t('brgen_playlist.new_comment_description') %>",
    "url": "<%= request.original_url %>"
  }
  </script>
<% end %>
<%= render "shared/header" %>
<%= tag.main role: "main" do %>
  <%= tag.section aria-labelledby: "new-comment-heading" do %>
    <%= tag.h1 t("brgen_playlist.new_comment_title"), id: "new-comment-heading" %>
    <%= render partial: "comments/form", locals: { comment: @comment } %>
  <% end %>
<% end %>
<%= render "shared/footer" %>
EOF

cat <<EOF > app/views/comments/edit.html.erb
<% content_for :title, t("brgen_playlist.edit_comment_title") %>
<% content_for :description, t("brgen_playlist.edit_comment_description") %>
<% content_for :keywords, t("brgen_playlist.edit_comment_keywords", default: "edit comment, brgen playlist, music") %>
<% content_for :schema do %>
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "WebPage",
    "name": "<%= t('brgen_playlist.edit_comment_title') %>",
    "description": "<%= t('brgen_playlist.edit_comment_description') %>",
    "url": "<%= request.original_url %>"
  }
  </script>
<% end %>
<%= render "shared/header" %>
<%= tag.main role: "main" do %>
  <%= tag.section aria-labelledby: "edit-comment-heading" do %>
    <%= tag.h1 t("brgen_playlist.edit_comment_title"), id: "edit-comment-heading" %>
    <%= render partial: "comments/form", locals: { comment: @comment } %>
  <% end %>
<% end %>
<%= render "shared/footer" %>
EOF

cat <<EOF > app/views/comments/show.html.erb
<% content_for :title, t("brgen_playlist.comment_title", playlist: @comment.playlist.name) %>
<% content_for :description, @comment.content&.truncate(160) %>
<% content_for :keywords, t("brgen_playlist.comment_keywords", playlist: @comment.playlist.name, default: "comment, #{@comment.playlist.name}, brgen playlist, music") %>
<% content_for :schema do %>
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "Comment",
    "text": "<%= @comment.content&.truncate(160) %>",
    "about": {
      "@type": "MusicPlaylist",
      "name": "<%= @comment.playlist.name %>"
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
    <%= tag.h1 t("brgen_playlist.comment_title", playlist: @comment.playlist.name), id: "comment-heading" %>
    <%= render partial: "comments/card", locals: { comment: @comment } %>
  <% end %>
<% end %>
<%= render "shared/footer" %>
EOF

generate_turbo_views "playlists" "playlist"
generate_turbo_views "comments" "comment"

commit "Brgen Playlist setup complete: Music playlist sharing platform with live search and anonymous features"

log "Brgen Playlist setup complete. Run 'bin/falcon-host' with PORT set to start on OpenBSD."

# Change Log:
# - Aligned with master.json v6.5.0: Two-space indents, double quotes, heredocs, Strunk & White comments.
# - Used Rails 8 conventions, Hotwire, Turbo Streams, Stimulus Reflex, I18n, and Falcon.
# - Leveraged bin/rails generate scaffold for Playlists and Comments to streamline CRUD setup.
# - Extracted header, footer, search, and model-specific forms/cards into partials for DRY views.
# - Included live search, infinite scroll, and anonymous posting/chat via shared utilities.
# - Ensured NNG principles, SEO, schema data, and minimal flat design compliance.
# - Finalized for unprivileged user on OpenBSD 7.5.