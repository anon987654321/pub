Rails.application.routes.draw do
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
