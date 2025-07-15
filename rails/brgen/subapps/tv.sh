#!/usr/bin/env zsh
# Brgen TV: AI-generated video content streaming platform with cognitive framework implementation
# Master.json v10.7.0 compliance with zero-trust security and intelligent content curation

set -e
setopt extended_glob null_glob

# === COGNITIVE FRAMEWORK CONFIGURATION ===
APP_NAME="brgen_tv"
BASE_DIR="/home/dev/rails"
BRGEN_IP="46.23.95.45"

# Source enhanced shared functionality
source "../../__shared_enhanced.sh"

# === TV-SPECIFIC CONFIGURATION ===
generate_application_code() {
  phase_transition "tv_code_generation" "Creating intelligent video streaming platform features"
  
  # Generate models with cognitive constraints (7 concepts max)
  bin/rails generate model Show title:string description:text genre:string creator:references
  bin/rails generate model Episode show:references title:string description:text duration:integer episode_number:integer
  bin/rails generate model VideoContent episode:references file_path:string resolution:string file_size:integer
  bin/rails generate model ViewingSession user:references episode:references watched_duration:integer completed:boolean
  bin/rails generate model Subscription user:references show:references active:boolean
  bin/rails generate model ContentRating user:references episode:references rating:integer
  bin/rails generate model WatchLater user:references episode:references
  
  # Database migrations
  bin/rails db:migrate
  
  # Enhanced TV implementation with cognitive load management
  log "TV application code generation completed" "INFO"
}

# Override main to use enhanced installation
main() {
  log "Starting Brgen TV installation with cognitive framework" "INFO"
  
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
    generate_application_code  # This will use our TV-specific implementation
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

bin/rails generate scaffold Show title:string genre:string description:text release_date:date rating:decimal duration:integer user:references poster:attachment trailer_url:string
bin/rails generate scaffold Episode title:string description:text duration:integer episode_number:integer season_number:integer show:references video_url:string
bin/rails generate scaffold Viewing show:references episode:references user:references progress:integer watched:boolean

cat <<EOF > app/reflexes/shows_infinite_scroll_reflex.rb
class ShowsInfiniteScrollReflex < InfiniteScrollReflex
  def load_more
    @pagy, @collection = pagy(Show.all.order(release_date: :desc), page: page)
    super
  end
end
EOF

cat <<EOF > app/reflexes/episodes_infinite_scroll_reflex.rb
class EpisodesInfiniteScrollReflex < InfiniteScrollReflex
  def load_more
    @pagy, @collection = pagy(Episode.where(show: current_show).order(:season_number, :episode_number), page: page)
    super
  end
end
EOF

cat <<EOF > app/controllers/shows_controller.rb
class ShowsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_show, only: [:show, :edit, :update, :destroy]

  def index
    @pagy, @shows = pagy(Show.all.order(release_date: :desc)) unless @stimulus_reflex
  end

  def show
    @episodes = @show.episodes.order(:season_number, :episode_number)
    @viewing = current_user&.viewings&.find_by(show: @show)
  end

  def new
    @show = current_user.shows.build
  end

  def create
    @show = current_user.shows.build(show_params)
    if @show.save
      redirect_to @show, notice: t("tv.show_created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @show.update(show_params)
      redirect_to @show, notice: t("tv.show_updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @show.destroy
    redirect_to shows_url, notice: t("tv.show_destroyed")
  end

  def search
    @pagy, @shows = pagy(Show.where("title ILIKE ? OR description ILIKE ?", "%#{params[:q]}%", "%#{params[:q]}%"))
    render :index
  end

  def by_genre
    @pagy, @shows = pagy(Show.where(genre: params[:genre]).order(release_date: :desc))
    render :index
  end

  private

  def set_show
    @show = Show.find(params[:id])
  end

  def show_params
    params.require(:show).permit(:title, :genre, :description, :release_date, :duration, :trailer_url, :poster)
  end
end
EOF

cat <<EOF > app/controllers/episodes_controller.rb
class EpisodesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_show
  before_action :set_episode, only: [:show, :edit, :update, :destroy, :watch]

  def index
    @episodes = @show.episodes.order(:season_number, :episode_number)
  end

  def show
    @viewing = current_user.viewings.find_or_initialize_by(show: @show, episode: @episode)
  end

  def new
    @episode = @show.episodes.build
  end

  def create
    @episode = @show.episodes.build(episode_params)
    if @episode.save
      redirect_to [@show, @episode], notice: t("tv.episode_created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @episode.update(episode_params)
      redirect_to [@show, @episode], notice: t("tv.episode_updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @episode.destroy
    redirect_to show_episodes_url(@show), notice: t("tv.episode_destroyed")
  end

  def watch
    @viewing = current_user.viewings.find_or_create_by(show: @show, episode: @episode)
    respond_to do |format|
      format.html
      format.json { render json: @viewing }
    end
  end

  private

  def set_show
    @show = Show.find(params[:show_id])
  end

  def set_episode
    @episode = @show.episodes.find(params[:id])
  end

  def episode_params
    params.require(:episode).permit(:title, :description, :duration, :episode_number, :season_number, :video_url)
  end
end
EOF

cat <<EOF > app/controllers/viewings_controller.rb
class ViewingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_viewing, only: [:show, :update, :destroy]

  def index
    @pagy, @viewings = pagy(current_user.viewings.includes(:show, :episode).order(updated_at: :desc))
  end

  def show
  end

  def update
    if @viewing.update(viewing_params)
      render json: @viewing
    else
      render json: { errors: @viewing.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    @viewing.destroy
    redirect_to viewings_url, notice: t("tv.viewing_destroyed")
  end

  private

  def set_viewing
    @viewing = current_user.viewings.find(params[:id])
  end

  def viewing_params
    params.require(:viewing).permit(:progress, :watched)
  end
end
EOF

cat <<EOF > app/models/show.rb
class Show < ApplicationRecord
  belongs_to :user
  has_many :episodes, dependent: :destroy
  has_many :viewings, dependent: :destroy
  has_one_attached :poster

  validates :title, presence: true
  validates :genre, presence: true
  validates :description, presence: true
  validates :release_date, presence: true
  validates :duration, presence: true, numericality: { greater_than: 0 }
  validates :rating, numericality: { in: 0..10 }, allow_nil: true

  scope :by_genre, ->(genre) { where(genre: genre) }
  scope :recent, -> { where("release_date > ?", 1.year.ago) }
  scope :popular, -> { where("rating > ?", 7.0) }

  def total_episodes
    episodes.count
  end

  def latest_episode
    episodes.order(:season_number, :episode_number).last
  end
end
EOF

cat <<EOF > app/models/episode.rb
class Episode < ApplicationRecord
  belongs_to :show
  has_many :viewings, dependent: :destroy

  validates :title, presence: true
  validates :duration, presence: true, numericality: { greater_than: 0 }
  validates :episode_number, presence: true, numericality: { greater_than: 0 }
  validates :season_number, presence: true, numericality: { greater_than: 0 }
  validates :video_url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp }

  scope :by_season, ->(season) { where(season_number: season) }
  scope :in_order, -> { order(:season_number, :episode_number) }

  def next_episode
    show.episodes.where(
      "(season_number = ? AND episode_number > ?) OR season_number > ?",
      season_number, episode_number, season_number
    ).order(:season_number, :episode_number).first
  end

  def previous_episode
    show.episodes.where(
      "(season_number = ? AND episode_number < ?) OR season_number < ?",
      season_number, episode_number, season_number
    ).order(:season_number, :episode_number).last
  end
end
EOF

cat <<EOF > app/models/viewing.rb
class Viewing < ApplicationRecord
  belongs_to :show
  belongs_to :episode
  belongs_to :user

  validates :progress, presence: true, numericality: { greater_than_or_equal_to: 0 }

  scope :watched, -> { where(watched: true) }
  scope :in_progress, -> { where(watched: false).where("progress > 0") }
  scope :recent, -> { where("updated_at > ?", 1.week.ago) }

  def progress_percentage
    return 0 if episode.duration.zero?
    (progress.to_f / episode.duration * 100).round(1)
  end

  def mark_as_watched!
    update!(watched: true, progress: episode.duration)
  end
end
EOF

cat <<EOF > config/routes.rb
Rails.application.routes.draw do
  devise_for :users, controllers: { omniauth_callbacks: "omniauth_callbacks" }
  root "shows#index"

  resources :shows do
    resources :episodes do
      member do
        get :watch
      end
    end
  end

  resources :viewings, only: [:index, :show, :update, :destroy]

  get "search", to: "shows#search"
  get "genre/:genre", to: "shows#by_genre", as: :genre_shows
  get "my_shows", to: "viewings#index"
end
EOF

cat <<EOF > app/views/shows/index.html.erb
<% content_for :title, t("tv.shows_title") %>
<% content_for :description, t("tv.shows_description") %>
<% content_for :head do %>
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "TVSeries",
    "name": "<%= t('tv.app_name') %>",
    "description": "<%= t('tv.shows_description') %>"
  }
  </script>
<% end %>
<%= render "shared/header" %>
<%= tag.main role: "main" do %>
  <%= tag.section aria_labelledby: "shows-heading" do %>
    <%= tag.h1 t("tv.shows_title"), id: "shows-heading" %>
    <%= tag.div data: { turbo_frame: "notices" } do %>
      <%= render "shared/notices" %>
    <% end %>
    
    <%= tag.div class: "filter-bar" do %>
      <%= form_with url: search_path, method: :get, local: true, data: { turbo_stream: true } do |f| %>
        <%= f.text_field :q, placeholder: t("tv.search_placeholder"), data: { reflex: "input->Shows#search" } %>
      <% end %>
      
      <%= tag.div class: "genre-filters" do %>
        <% %w[Action Comedy Drama Horror Sci-Fi Documentary].each do |genre| %>
          <%= link_to genre, genre_shows_path(genre), class: "genre-button" %>
        <% end %>
      <% end %>
    <% end %>

    <%= link_to t("tv.new_show"), new_show_path, class: "button", "aria-label": t("tv.new_show") if current_user %>
    
    <%= turbo_frame_tag "shows", data: { controller: "infinite-scroll" } do %>
      <% @shows.each do |show| %>
        <%= render partial: "shows/card", locals: { show: show } %>
      <% end %>
      <%= tag.div id: "sentinel", class: "hidden", data: { reflex: "ShowsInfiniteScroll#load_more", next_page: @pagy.next || 2 } %>
    <% end %>
    <%= tag.button t("tv.load_more"), id: "load-more", data: { reflex: "click->ShowsInfiniteScroll#load_more", "next-page": @pagy.next || 2, "reflex-root": "#load-more" }, class: @pagy&.next ? "" : "hidden", "aria-label": t("tv.load_more") %>
  <% end %>
<% end %>
<%= render "shared/footer" %>
EOF

cat <<EOF > app/views/shows/_card.html.erb
<%= tag.article class: "show-card", data: { turbo_frame: "show_\#{show.id}" } do %>
  <%= tag.header do %>
    <%= link_to show_path(show) do %>
      <%= tag.h3 show.title %>
    <% end %>
    <%= tag.div class: "show-meta" do %>
      <%= tag.span show.genre, class: "genre" %>
      <%= tag.span "\#{show.rating}/10", class: "rating" if show.rating %>
      <%= tag.span "\#{show.total_episodes} episodes", class: "episode-count" %>
    <% end %>
  <% end %>
  
  <% if show.poster.attached? %>
    <%= tag.div class: "show-poster" do %>
      <%= image_tag show.poster, alt: show.title, loading: "lazy" %>
    <% end %>
  <% end %>

  <%= tag.div class: "show-info" do %>
    <%= tag.p truncate(show.description, length: 120), class: "description" %>
    <%= tag.div class: "show-details" do %>
      <%= tag.span time_ago_in_words(show.release_date), class: "release-date" %>
      <%= tag.span "\#{show.duration} min", class: "duration" %>
    <% end %>
  <% end %>

  <%= tag.footer do %>
    <%= link_to t("tv.watch_now"), show_path(show), class: "button primary" %>
    <% if show.trailer_url.present? %>
      <%= link_to t("tv.watch_trailer"), show.trailer_url, target: "_blank", class: "button secondary" %>
    <% end %>
  <% end %>
<% end %>
EOF

cat <<EOF > app/views/shows/show.html.erb
<% content_for :title, @show.title %>
<% content_for :description, @show.description %>
<%= render "shared/header" %>
<%= tag.main role: "main" do %>
  <%= tag.section aria_labelledby: "show-heading" do %>
    <%= tag.header class: "show-header" do %>
      <% if @show.poster.attached? %>
        <%= tag.div class: "show-poster-large" do %>
          <%= image_tag @show.poster, alt: @show.title %>
        <% end %>
      <% end %>
      
      <%= tag.div class: "show-info" do %>
        <%= tag.h1 @show.title, id: "show-heading" %>
        <%= tag.div class: "show-meta" do %>
          <%= tag.span @show.genre, class: "genre" %>
          <%= tag.span "\#{@show.rating}/10", class: "rating" if @show.rating %>
          <%= tag.span @show.release_date.year, class: "year" %>
          <%= tag.span "\#{@show.duration} min", class: "duration" %>
        <% end %>
        <%= tag.p @show.description, class: "description" %>
        
        <% if @show.trailer_url.present? %>
          <%= link_to t("tv.watch_trailer"), @show.trailer_url, target: "_blank", class: "button secondary" %>
        <% end %>
      <% end %>
    <% end %>

    <%= tag.section aria_labelledby: "episodes-heading" do %>
      <%= tag.h2 t("tv.episodes"), id: "episodes-heading" %>
      
      <% if @episodes.any? %>
        <% @episodes.group_by(&:season_number).each do |season, episodes| %>
          <%= tag.div class: "season" do %>
            <%= tag.h3 t("tv.season", number: season) %>
            <% episodes.each do |episode| %>
              <%= tag.div class: "episode" do %>
                <%= tag.div class: "episode-info" do %>
                  <%= tag.h4 "E\#{episode.episode_number}: \#{episode.title}" %>
                  <%= tag.p episode.description if episode.description.present? %>
                  <%= tag.span "\#{episode.duration} min", class: "duration" %>
                <% end %>
                <%= link_to t("tv.watch_episode"), watch_show_episode_path(@show, episode), class: "button primary" %>
              <% end %>
            <% end %>
          <% end %>
        <% end %>
      <% else %>
        <%= tag.p t("tv.no_episodes") %>
      <% end %>
    <% end %>
  <% end %>
<% end %>
<%= render "shared/footer" %>
EOF

cat <<EOF > app/views/episodes/watch.html.erb
<% content_for :title, "\#{@show.title} - \#{@episode.title}" %>
<%= render "shared/header" %>
<%= tag.main role: "main", class: "video-player-page" do %>
  <%= tag.section aria_labelledby: "episode-heading" do %>
    <%= tag.div class: "video-container" do %>
      <% if @episode.video_url.present? %>
        <%= tag.video controls: true, data: { controller: "video-player", "video-player-viewing-id-value": @viewing.id } do %>
          <%= tag.source src: @episode.video_url, type: "video/mp4" %>
        <% end %>
      <% else %>
        <%= tag.div class: "video-placeholder" do %>
          <%= tag.p t("tv.video_not_available") %>
        <% end %>
      <% end %>
    <% end %>

    <%= tag.div class: "episode-info" do %>
      <%= tag.h1 @episode.title, id: "episode-heading" %>
      <%= tag.div class: "episode-meta" do %>
        <%= link_to @show.title, show_path(@show), class: "show-link" %>
        <%= tag.span "Season \#{@episode.season_number}, Episode \#{@episode.episode_number}", class: "episode-number" %>
        <%= tag.span "\#{@episode.duration} min", class: "duration" %>
      <% end %>
      <%= tag.p @episode.description if @episode.description.present? %>
    <% end %>

    <%= tag.div class: "episode-navigation" do %>
      <% if @episode.previous_episode %>
        <%= link_to t("tv.previous_episode"), watch_show_episode_path(@show, @episode.previous_episode), class: "button secondary" %>
      <% end %>
      <% if @episode.next_episode %>
        <%= link_to t("tv.next_episode"), watch_show_episode_path(@show, @episode.next_episode), class: "button primary" %>
      <% end %>
    <% end %>
  <% end %>
<% end %>
<%= render "shared/footer" %>
EOF

cat <<EOF > config/locales/tv.en.yml
en:
  tv:
    app_name: "Brgen TV"
    shows_title: "TV Shows & Series"
    shows_description: "Discover and watch AI-generated video content and series"
    show_created: "Show was successfully created."
    show_updated: "Show was successfully updated."
    show_destroyed: "Show was successfully deleted."
    episode_created: "Episode was successfully created."
    episode_updated: "Episode was successfully updated."
    episode_destroyed: "Episode was successfully deleted."
    viewing_destroyed: "Viewing history was successfully deleted."
    new_show: "Add New Show"
    watch_now: "Watch Now"
    watch_trailer: "Watch Trailer"
    watch_episode: "Watch Episode"
    episodes: "Episodes"
    season: "Season %{number}"
    no_episodes: "No episodes available yet."
    search_placeholder: "Search shows and series..."
    load_more: "Load More"
    video_not_available: "Video not available"
    previous_episode: "Previous Episode"
    next_episode: "Next Episode"
EOF

cat <<EOF > app/assets/stylesheets/tv.scss
// Brgen TV - Video streaming platform styles

.show-card {
  border: 1px solid #e0e0e0;
  border-radius: 8px;
  overflow: hidden;
  margin-bottom: 1rem;
  background: white;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
  transition: transform 0.2s ease;

  &:hover {
    transform: translateY(-2px);
  }

  header {
    padding: 1rem;

    h3 {
      margin: 0;
      font-size: 1.2rem;
      color: #673ab7;
    }

    .show-meta {
      display: flex;
      gap: 1rem;
      margin-top: 0.5rem;
      flex-wrap: wrap;

      .genre {
        background: #f3e5f5;
        color: #673ab7;
        padding: 0.25rem 0.5rem;
        border-radius: 4px;
        font-size: 0.8rem;
      }

      .rating {
        color: #ff9800;
        font-weight: bold;
      }

      .episode-count {
        color: #666;
        font-size: 0.9rem;
      }
    }
  }

  .show-poster {
    width: 100%;
    height: 200px;
    overflow: hidden;

    img {
      width: 100%;
      height: 100%;
      object-fit: cover;
    }
  }

  .show-info {
    padding: 1rem;

    .description {
      color: #666;
      margin: 0.5rem 0;
      line-height: 1.4;
    }

    .show-details {
      display: flex;
      gap: 1rem;
      font-size: 0.9rem;
      color: #888;
    }
  }

  footer {
    padding: 1rem;
    display: flex;
    gap: 0.5rem;

    .button {
      flex: 1;
      text-align: center;
      padding: 0.5rem 1rem;
      border-radius: 4px;
      text-decoration: none;
      border: none;
      cursor: pointer;

      &.primary {
        background: #673ab7;
        color: white;
      }

      &.secondary {
        background: #f5f5f5;
        color: #333;
      }
    }
  }
}

.show-header {
  display: flex;
  gap: 2rem;
  margin-bottom: 2rem;
  align-items: flex-start;

  .show-poster-large {
    flex-shrink: 0;
    width: 300px;

    img {
      width: 100%;
      border-radius: 8px;
    }
  }

  .show-info {
    flex: 1;

    h1 {
      color: #673ab7;
      margin-bottom: 1rem;
    }

    .show-meta {
      display: flex;
      gap: 1rem;
      margin-bottom: 1rem;
      flex-wrap: wrap;

      .genre {
        background: #f3e5f5;
        color: #673ab7;
        padding: 0.5rem 1rem;
        border-radius: 4px;
      }

      .rating {
        color: #ff9800;
        font-weight: bold;
      }

      .year, .duration {
        color: #666;
      }
    }

    .description {
      line-height: 1.6;
      margin-bottom: 1rem;
    }
  }
}

.season {
  margin-bottom: 2rem;

  h3 {
    border-bottom: 2px solid #673ab7;
    padding-bottom: 0.5rem;
    color: #673ab7;
    margin-bottom: 1rem;
  }

  .episode {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 1rem;
    border: 1px solid #eee;
    border-radius: 4px;
    margin-bottom: 0.5rem;

    .episode-info {
      flex: 1;

      h4 {
        margin: 0 0 0.5rem 0;
        color: #333;
      }

      p {
        margin: 0 0 0.5rem 0;
        color: #666;
      }

      .duration {
        font-size: 0.9rem;
        color: #888;
      }
    }

    .button {
      margin-left: 1rem;
      padding: 0.5rem 1rem;
      background: #673ab7;
      color: white;
      text-decoration: none;
      border-radius: 4px;
    }
  }
}

.video-player-page {
  max-width: 1200px;
  margin: 0 auto;
  padding: 1rem;

  .video-container {
    margin-bottom: 2rem;
    background: #000;
    border-radius: 8px;
    overflow: hidden;

    video {
      width: 100%;
      height: auto;
    }

    .video-placeholder {
      aspect-ratio: 16/9;
      display: flex;
      align-items: center;
      justify-content: center;
      color: white;
      font-size: 1.2rem;
    }
  }

  .episode-info {
    margin-bottom: 2rem;

    h1 {
      color: #673ab7;
      margin-bottom: 1rem;
    }

    .episode-meta {
      display: flex;
      gap: 1rem;
      margin-bottom: 1rem;
      flex-wrap: wrap;

      .show-link {
        color: #673ab7;
        text-decoration: none;
        font-weight: bold;
      }

      .episode-number {
        color: #666;
      }

      .duration {
        color: #888;
      }
    }
  }

  .episode-navigation {
    display: flex;
    gap: 1rem;
    justify-content: center;

    .button {
      padding: 0.75rem 1.5rem;
      border-radius: 4px;
      text-decoration: none;
      border: none;
      cursor: pointer;

      &.primary {
        background: #673ab7;
        color: white;
      }

      &.secondary {
        background: #f5f5f5;
        color: #333;
      }
    }
  }
}

.filter-bar {
  margin-bottom: 2rem;
  display: flex;
  gap: 1rem;
  flex-wrap: wrap;

  input[type="text"] {
    flex: 1;
    min-width: 200px;
    padding: 0.5rem;
    border: 1px solid #ddd;
    border-radius: 4px;
  }

  .genre-filters {
    display: flex;
    gap: 0.5rem;
    flex-wrap: wrap;

    .genre-button {
      padding: 0.5rem 1rem;
      background: #f5f5f5;
      color: #333;
      text-decoration: none;
      border-radius: 4px;
      font-size: 0.9rem;

      &:hover {
        background: #673ab7;
        color: white;
      }
    }
  }
}

@media (max-width: 768px) {
  .show-header {
    flex-direction: column;

    .show-poster-large {
      width: 100%;
      max-width: 300px;
      margin: 0 auto;
    }
  }

  .episode {
    flex-direction: column;
    align-items: flex-start !important;

    .button {
      margin-left: 0 !important;
      margin-top: 1rem;
      align-self: stretch;
    }
  }

  .filter-bar {
    flex-direction: column;

    input[type="text"] {
      min-width: auto;
    }
  }
}
EOF

bin/rails db:migrate

log "Brgen TV setup complete"

