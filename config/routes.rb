Rails.application.routes.draw do
  root "home#prehrajto"
  match "lang/:locale", to: "home#change_locale", as: :change_locale, via: [:get]
  get "/formula", to: "home#formula"
end
