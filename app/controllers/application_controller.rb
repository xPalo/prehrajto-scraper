require "nokogiri"
require "httparty"

class ApplicationController < ActionController::Base
  PRODUCTION_URL = "http://62.65.160.178:46580/"

  protect_from_forgery with: :exception
  
  before_action :set_default_url_options, if: :production?
  before_action :set_locale
  before_action :set_theme

  rescue_from ActionController::Redirecting::UnsafeRedirectError do
    redirect_to(root_url, allow_other_host: true)
  end
  
  def default_url_options
    production? ? { host: '62.65.160.178', port: 46580 } : super
  end
  
  def set_locale
    if cookies[:lang] && I18n.available_locales.include?(cookies[:lang].to_s.strip.to_sym)
      lang = cookies[:lang].to_s.strip.to_sym
    else
      lang = I18n.default_locale
      cookies[:lang] = lang
    end

    I18n.locale = lang
  end
  
  def after_sign_in_path_for(resource)
    Rails.env.production? ? PRODUCTION_URL : super
  end

  def after_sign_up_path_for(resource)
    Rails.env.production? ? PRODUCTION_URL : super
  end

  def after_sign_out_path_for(resource)
    Rails.env.production? ? PRODUCTION_URL : super
  end

  def set_theme
    @dark_mode = cookies[:theme] == "dark"
  end

  private

  def set_default_url_options
    port = request.port
    protocol = request.protocol.delete_suffix('://')
    host = request.host

    Rails.application.routes.default_url_options = {
      host: host,
      port: port == 80 ? nil : port,
      protocol: protocol
    }
  end

  def production?
    Rails.env.production?
  end
end
