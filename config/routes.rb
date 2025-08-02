Rails.application.routes.draw do
  devise_for :users
  resources :favs
  resources :watchdogs, except: [:show]
  resources :users, only: [:index]
  root "home#prehrajto"
  match "lang/:locale", to: "home#change_locale", as: :change_locale, via: [:get]
end
