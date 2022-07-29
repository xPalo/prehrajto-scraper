require "nokogiri"
require "httparty"

class ApplicationController < ActionController::Base
  before_action :set_locale

  def set_locale
    if cookies[:lang] && I18n.available_locales.include?(cookies[:lang].to_s.strip.to_sym)
      lang = cookies[:lang].to_s.strip.to_sym
    else
      lang = I18n.default_locale
      cookies[:lang] = lang
    end
    I18n.locale = lang
  end
end
