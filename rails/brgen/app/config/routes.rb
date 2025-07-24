Rails.application.routes.draw do
  get "search/index"
  get "comments/create"
  get "comments/edit"
  get "comments/update"
  get "comments/destroy"
  get "users/show"
  get "users/edit"
  get "users/update"
  get "users/follow"
  get "users/unfollow"
  devise_for :users
  root 'home#index'
  
  # Core social platform routes
  resources :posts do
    resources :comments, except: [:index, :show]
    member do
      post :like
      delete :unlike
    end
  end
  
  resources :users, only: [:show, :edit, :update] do
    member do
      post :follow
      delete :unfollow
    end
  end
  
  # Direct messaging
  resources :direct_messages, only: [:index, :show, :create, :destroy] do
    member do
      patch :mark_as_read
    end
  end
  
  # Notifications
  resources :notifications, only: [:index, :destroy] do
    collection do
      patch :mark_all_as_read
    end
    member do
      patch :mark_as_read
    end
  end
  
  # Search
  get 'search', to: 'search#index'
  
  # Business Planning routes
  resources :business_planning, only: [:index], path: 'business-planning' do
    collection do
      # Lean Canvas
      get :lean_canvas, path: 'lean-canvas'
      post :create_lean_canvas, path: 'lean-canvas'
      patch 'lean-canvas/:id', to: 'business_planning#update_lean_canvas', as: :update_lean_canvas
      
      # OKRs
      get :okrs
      post :create_okr, path: 'okrs'
      patch 'okrs/:okr_id/progress', to: 'business_planning#update_okr_progress', as: :update_okr_progress
      
      # Stakeholder Mapping
      get :stakeholders
      post :create_stakeholders, path: 'stakeholders'
      
      # Design Thinking
      get :design_thinking, path: 'design-thinking'
      post :create_design_thinking, path: 'design-thinking'
      patch 'design-thinking/:session_id', to: 'business_planning#update_design_thinking', as: :update_design_thinking
      
      # Analytics and Insights
      get :insights
      post :trading_integration, path: 'trading-integration'
    end
  end

  # AI3 Integration routes
  resources :ai3, only: [:index], path: 'ai3' do
    collection do
      get :search
      post :add_knowledge, path: 'knowledge'
      get :history
      get :health
    end
    
    member do
      get :show, path: ':assistant_name', as: :assistant
      post :query, path: ':assistant_name/query'
      get :capabilities, path: ':assistant_name/capabilities'
    end
  end
  
  # API for real-time features
  namespace :api do
    namespace :v1 do
      resources :notifications, only: [:index]
      resources :direct_messages, only: [:index, :create]
    end
  end
  
  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
  
  # PWA files
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
end
