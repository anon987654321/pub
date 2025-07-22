#!/bin/bash

#!/usr/bin/env zsh
set -e

# Brgen Playlist setup: Music playlist sharing platform with live search, infinite scroll, and anonymous features on OpenBSD 7.5, unprivileged user

APP_NAME="brgen_playlist"
BASE_DIR="/home/dev/rails"
BRGEN_IP="46.23.95.45"

source "./__shared.sh"

log "Starting Brgen Playlist setup"

setup_full_app "$APP_NAME"

command_exists "ruby"
command_exists "node"
command_exists "psql"
command_exists "redis-server"

# Generate enhanced models with SEO and karma support
bin/rails generate scaffold Playlist name:string slug:string description:text user:references tracks:text is_public:boolean play_count:integer karma_score:integer
bin/rails generate scaffold Track title:string artist:string duration:integer spotify_url:string youtube_url:string playlist:references position:integer
bin/rails generate scaffold Comment playlist:references user:references content:text karma_score:integer
bin/rails generate scaffold PlaylistFollow playlist:references user:references
bin/rails generate scaffold PlaylistRating playlist:references user:references rating:integer

# Add karma and reputation tracking for playlist features  
bin/rails generate model PlaylistKarma user:references playlist_karma:integer track_karma:integer comment_karma:integer follow_karma:integer total_karma:integer level:integer

# Enhanced infinite scroll reflexes with analytics and social features
cat <<EOF > app/reflexes/playlists_infinite_scroll_reflex.rb
class PlaylistsInfiniteScrollReflex < InfiniteScrollReflex
  def load_more
    @pagy, @collection = pagy(
      Playlist.includes(:user, :tracks, :playlist_follows)
              .where(tenant: ActsAsTenant.current_tenant, is_public: true)
              .order(created_at: :desc), 
      page: page
    )
    ahoy.track "Playlists infinite scroll", { page: page, tenant: ActsAsTenant.current_tenant&.name }
    super
  end
end
EOF

cat <<EOF > app/reflexes/comments_infinite_scroll_reflex.rb
class CommentsInfiniteScrollReflex < InfiniteScrollReflex
  def load_more
    playlist = Playlist.find(element.dataset["playlist_id"])
    @pagy, @collection = pagy(playlist.comments.includes(:user).order(created_at: :desc), page: page)
    ahoy.track "Comments infinite scroll", { playlist_id: playlist.id, page: page }
    super
  end
end
EOF

# Enhanced playlist voting system
cat <<EOF > app/reflexes/playlist_vote_reflex.rb
class PlaylistVoteReflex < ApplicationReflex
  def upvote
    playlist = Playlist.find(element.dataset["playlist_id"])
    vote = current_user.votes.find_or_initialize_by(votable: playlist)
    
    if vote.persisted? && vote.vote_flag
      # Already upvoted, remove vote
      vote.destroy
      KarmaAction.create!(user: playlist.user, target: playlist, action_type: 'vote_removed', points: -1)
    else
      # Create or change to upvote
      vote.destroy if vote.persisted?
      playlist.upvote_by current_user
      KarmaAction.create!(user: playlist.user, target: playlist, action_type: 'upvote', points: 3)
      
      # Update user karma
      karma = playlist.user.playlist_karma || playlist.user.create_playlist_karma
      karma.increment!(:playlist_karma, 3)
      karma.update!(total_karma: karma.playlist_karma + karma.track_karma + karma.comment_karma + karma.follow_karma)
    end
    
    ahoy.track "Playlist vote", { playlist_id: playlist.id, action: 'upvote' }
    cable_ready.replace(selector: "#playlist-vote-#{playlist.id}", html: render(partial: "shared/vote_buttons", locals: { votable: playlist })).broadcast
  end

  def downvote
    playlist = Playlist.find(element.dataset["playlist_id"])
    vote = current_user.votes.find_or_initialize_by(votable: playlist)
    
    if vote.persisted? && !vote.vote_flag
      # Already downvoted, remove vote  
      vote.destroy
      KarmaAction.create!(user: playlist.user, target: playlist, action_type: 'vote_removed', points: 1)
    else
      # Create or change to downvote
      vote.destroy if vote.persisted?
      playlist.downvote_by current_user
      KarmaAction.create!(user: playlist.user, target: playlist, action_type: 'downvote', points: -1)
      
      # Update user karma
      karma = playlist.user.playlist_karma || playlist.user.create_playlist_karma
      karma.decrement!(:playlist_karma, 1)
      karma.update!(total_karma: karma.playlist_karma + karma.track_karma + karma.comment_karma + karma.follow_karma)
    end
    
    ahoy.track "Playlist vote", { playlist_id: playlist.id, action: 'downvote' }
    cable_ready.replace(selector: "#playlist-vote-#{playlist.id}", html: render(partial: "shared/vote_buttons", locals: { votable: playlist })).broadcast
  end
end
EOF

# Playlist follow/unfollow reflex
cat <<EOF > app/reflexes/playlist_follow_reflex.rb
class PlaylistFollowReflex < ApplicationReflex
  def toggle_follow
    playlist = Playlist.find(element.dataset["playlist_id"])
    follow = current_user.playlist_follows.find_by(playlist: playlist)
    
    if follow
      # Unfollow
      follow.destroy
      KarmaAction.create!(user: playlist.user, target: playlist, action_type: 'unfollowed', points: -1)
      action = 'unfollowed'
    else
      # Follow
      current_user.playlist_follows.create!(playlist: playlist)
      KarmaAction.create!(user: playlist.user, target: playlist, action_type: 'followed', points: 2)
      
      # Update playlist creator's karma
      karma = playlist.user.playlist_karma || playlist.user.create_playlist_karma
      karma.increment!(:follow_karma, 2)
      karma.update!(total_karma: karma.playlist_karma + karma.track_karma + karma.comment_karma + karma.follow_karma)
      action = 'followed'
    end
    
    ahoy.track "Playlist follow", { playlist_id: playlist.id, action: action }
    cable_ready.replace(selector: "#playlist-follow-#{playlist.id}", html: render(partial: "playlists/follow_button", locals: { playlist: playlist })).broadcast
  end
end
EOF

# Enhanced controllers with analytics and SEO
cat <<EOF > app/controllers/playlists_controller.rb
class PlaylistsController < ApplicationController
  include AnalyticsTracking
  include GitTracking
  
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_playlist, only: [:show, :edit, :update, :destroy, :play]

  def index
    @pagy, @playlists = pagy(
      Playlist.includes(:user, :tracks, :playlist_follows)
              .where(tenant: ActsAsTenant.current_tenant, is_public: true)
              .order(created_at: :desc)
    ) unless @stimulus_reflex
    
    # SEO optimization
    @seo_title = "Music Playlists - #{ActsAsTenant.current_tenant&.name || 'Brgen Playlist'}"
    @seo_description = "Discover and share music playlists in your community"
    @seo_keywords = "music, playlists, spotify, youtube, community, #{ActsAsTenant.current_tenant&.name}"
    
    ahoy.track "Playlists index", { 
      playlists_count: @playlists&.count || 0,
      tenant: ActsAsTenant.current_tenant&.name
    }
  end

  def show
    @tracks = @playlist.tracks.order(:position)
    @comments = @playlist.comments.includes(:user).order(created_at: :desc).limit(10)
    @user_comment = Comment.new
    @user_rating = current_user&.playlist_ratings&.find_by(playlist: @playlist)
    @is_following = current_user&.playlist_follows&.exists?(playlist: @playlist)
    
    # Increment play count
    @playlist.increment!(:play_count)
    
    # SEO for individual playlist
    @seo_title = @playlist.name
    @seo_description = truncate(@playlist.description, length: 160)
    @seo_keywords = "#{@playlist.name}, music playlist, #{@tracks.map(&:artist).uniq.join(', ')}"
    
    # Schema.org structured data
    @schema_data = {
      "@context" => "https://schema.org",
      "@type" => "MusicPlaylist",
      "name" => @playlist.name,
      "description" => @playlist.description,
      "numTracks" => @tracks.count,
      "creator" => {
        "@type" => "Person",
        "name" => @playlist.user.email
      }
    }
    
    ahoy.track "Playlist view", { 
      playlist_id: @playlist.id,
      playlist_name: @playlist.name,
      track_count: @tracks.count
    }
  end

  def new
    @playlist = current_user.playlists.build
  end

  def create
    @playlist = current_user.playlists.build(playlist_params)
    @playlist.tenant = ActsAsTenant.current_tenant
    @playlist.slug = @playlist.name.parameterize if @playlist.name
    
    if @playlist.save
      # Award karma for content creation
      karma = current_user.playlist_karma || current_user.create_playlist_karma
      karma.increment!(:playlist_karma, 10)
      karma.update!(total_karma: karma.playlist_karma + karma.track_karma + karma.comment_karma + karma.follow_karma)
      
      KarmaAction.create!(user: current_user, target: @playlist, action_type: 'content_created', points: 10)
      
      ahoy.track "Playlist created", { playlist_id: @playlist.id, name: @playlist.name }
      PublicActivity::Activity.create!(trackable: @playlist, owner: current_user, key: 'playlist.create')
      
      redirect_to @playlist, notice: 'Playlist was successfully created.'
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @playlist.update(playlist_params)
      @playlist.update(slug: @playlist.name.parameterize) if playlist_params[:name]
      ahoy.track "Playlist updated", { playlist_id: @playlist.id, name: @playlist.name }
      PublicActivity::Activity.create!(trackable: @playlist, owner: current_user, key: 'playlist.update')
      redirect_to @playlist, notice: 'Playlist was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    playlist_name = @playlist.name
    @playlist.destroy
    ahoy.track "Playlist deleted", { name: playlist_name }
    redirect_to playlists_url, notice: 'Playlist was successfully deleted.'
  end

  def play
    # Track playlist plays for analytics
    ahoy.track "Playlist played", { 
      playlist_id: @playlist.id,
      playlist_name: @playlist.name
    }
    
    # Return playlist data for JavaScript player
    render json: {
      id: @playlist.id,
      name: @playlist.name,
      tracks: @tracks.map do |track|
        {
          id: track.id,
          title: track.title,
          artist: track.artist,
          duration: track.duration,
          spotify_url: track.spotify_url,
          youtube_url: track.youtube_url,
          position: track.position
        }
      end
    }
  end

  private

  def set_playlist
    @playlist = Playlist.friendly.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    @playlist = Playlist.find(params[:id])
  end

  def playlist_params
    params.require(:playlist).permit(:name, :description, :is_public)
  end
end
EOF

# Enhanced tracks controller
cat <<EOF > app/controllers/tracks_controller.rb
class TracksController < ApplicationController
  include AnalyticsTracking
  include GitTracking
  
  before_action :authenticate_user!
  before_action :set_playlist
  before_action :set_track, only: [:show, :edit, :update, :destroy, :move_up, :move_down]
  before_action :check_playlist_owner, except: [:show]

  def show
    ahoy.track "Track view", {
      track_id: @track.id,
      playlist_id: @playlist.id,
      title: @track.title,
      artist: @track.artist
    }
  end

  def new
    @track = @playlist.tracks.build
    @track.position = (@playlist.tracks.maximum(:position) || 0) + 1
  end

  def create
    @track = @playlist.tracks.build(track_params)
    @track.position = (@playlist.tracks.maximum(:position) || 0) + 1
    
    if @track.save
      # Award karma for adding tracks
      karma = current_user.playlist_karma || current_user.create_playlist_karma
      karma.increment!(:track_karma, 2)
      karma.update!(total_karma: karma.playlist_karma + karma.track_karma + karma.comment_karma + karma.follow_karma)
      
      KarmaAction.create!(user: current_user, target: @track, action_type: 'track_added', points: 2)
      
      ahoy.track "Track created", {
        track_id: @track.id,
        playlist_id: @playlist.id,
        title: @track.title,
        artist: @track.artist
      }
      
      redirect_to @playlist, notice: 'Track was successfully added.'
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @track.update(track_params)
      ahoy.track "Track updated", { track_id: @track.id, playlist_id: @playlist.id }
      redirect_to @playlist, notice: 'Track was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    track_title = @track.title
    @track.destroy
    # Reorder remaining tracks
    @playlist.tracks.where('position > ?', @track.position).update_all('position = position - 1')
    
    ahoy.track "Track deleted", { playlist_id: @playlist.id, title: track_title }
    redirect_to @playlist, notice: 'Track was successfully removed.'
  end

  def move_up
    return if @track.position <= 1
    
    swap_with = @playlist.tracks.find_by(position: @track.position - 1)
    if swap_with
      @track.update!(position: @track.position - 1)
      swap_with.update!(position: swap_with.position + 1)
    end
    
    redirect_to @playlist
  end

  def move_down
    max_position = @playlist.tracks.maximum(:position)
    return if @track.position >= max_position
    
    swap_with = @playlist.tracks.find_by(position: @track.position + 1)
    if swap_with
      @track.update!(position: @track.position + 1)
      swap_with.update!(position: swap_with.position - 1)
    end
    
    redirect_to @playlist
  end

  private

  def set_playlist
    @playlist = Playlist.friendly.find(params[:playlist_id])
  rescue ActiveRecord::RecordNotFound
    @playlist = Playlist.find(params[:playlist_id])
  end

  def set_track
    @track = @playlist.tracks.find(params[:id])
  end

  def check_playlist_owner
    redirect_to @playlist, alert: 'Not authorized' unless @playlist.user == current_user
  end

  def track_params
    params.require(:track).permit(:title, :artist, :duration, :spotify_url, :youtube_url)
  end
end
EOF
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

# Enhanced models with SEO, caching, and social features
cat <<EOF > app/models/playlist.rb
class Playlist < ApplicationRecord
  extend FriendlyId
  include Cacheable
  include SitemapGenerator
  
  acts_as_tenant(:tenant, class_name: 'City')
  acts_as_votable
  
  friendly_id :name, use: [:slugged, :scoped], scope: :tenant
  
  belongs_to :user
  belongs_to :tenant, class_name: 'City', optional: true
  has_many :tracks, -> { order(:position) }, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :playlist_follows, dependent: :destroy
  has_many :playlist_ratings, dependent: :destroy
  has_many :followers, through: :playlist_follows, source: :user
  has_many :karma_actions, as: :target, dependent: :destroy
  
  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :description, presence: true, length: { minimum: 10, maximum: 500 }
  validates :play_count, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :karma_score, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  
  scope :public_playlists, -> { where(is_public: true) }
  scope :popular, -> { order(karma_score: :desc, play_count: :desc) }
  scope :recent, -> { order(created_at: :desc) }
  scope :trending, -> { where('play_count > ? AND created_at > ?', 50, 1.week.ago).order(:play_count) }
  
  before_save :calculate_karma_score
  after_commit :update_sitemap, if: :should_update_sitemap?
  
  def should_regenerate_slug?
    name_changed? || slug.blank?
  end
  
  def average_rating
    playlist_ratings.average(:rating)&.round(1) || 0
  end
  
  def total_duration
    tracks.sum(:duration)
  end
  
  def followers_count
    playlist_follows.count
  end
  
  def trending?
    play_count > 50 && created_at > 1.week.ago
  end
  
  def formatted_duration
    total_seconds = total_duration
    hours = total_seconds / 3600
    minutes = (total_seconds % 3600) / 60
    seconds = total_seconds % 60
    
    if hours > 0
      "%d:%02d:%02d" % [hours, minutes, seconds]
    else
      "%d:%02d" % [minutes, seconds]
    end
  end
  
  private
  
  def calculate_karma_score
    self.karma_score = (get_upvotes.size * 3) - (get_downvotes.size * 1) + 
                       (playlist_follows.count * 2) + 
                       (comments.count * 1) + 
                       (play_count / 5)
  end
  
  def should_update_sitemap?
    saved_change_to_name? || saved_change_to_slug? || saved_change_to_is_public?
  end
  
  def update_sitemap
    SitemapRegenerateJob.perform_later if is_public?
  end
end
EOF

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