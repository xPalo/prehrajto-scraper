require 'sidekiq/web'
require 'sidekiq/cron/web'

Rails.application.routes.draw do
  devise_for :users

  authenticate :user, ->(user) { user.is_admin? } do
    mount Sidekiq::Web => '/sidekiq'
  end

  resources :favs
  resources :watchdogs
  resources :videos do
    member do
      get :download
    end
  end
  resources :users, only: [:index]

  root "home#prehrajto"

  match "lang/:locale", to: "home#change_locale", as: :change_locale, via: [:get]
end
