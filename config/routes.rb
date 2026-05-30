require 'sidekiq/web'
require 'sidekiq/cron/web'

Rails.application.routes.draw do
  devise_for :users

  devise_scope :user do
    post "users/otp",        to: "otp_sessions#create",  as: :user_otp_request
    get  "users/otp/verify", to: "otp_sessions#verify",  as: :user_otp_verify
    post "users/otp/verify", to: "otp_sessions#confirm",  as: :user_otp_confirm
  end

  authenticate :user, ->(user) { user.is_admin? } do
    mount Sidekiq::Web => '/sidekiq'
  end

  resources :favs
  resources :watchdogs
  resources :videos do
    collection do
      get  :from_url
      post :from_url, action: :create_from_url
    end
    member do
      get :download
      get :stream
    end
  end
  resources :users, only: [:index]

  root "home#prehrajto"

  get "similar", to: "home#similar", as: :similar
  match "lang/:locale", to: "home#change_locale", as: :change_locale, via: [:get]
end
