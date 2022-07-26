require_relative "boot"

require "rails/all"
Bundler.require(*Rails.groups)

module PrehrajtoScraper
  class Application < Rails::Application

    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins "http://localhost:3030", /https*:\/\/.*?prehrajto\.cz/
        resource "*", :headers => :any, :methods => :any
      end
    end

    $stdout.sync = true
    config.logger = Logger.new(STDOUT)
    config.time_zone = "Europe/Bratislava"
    config.active_record.default_timezone = :local
    config.active_record.time_zone_aware_attributes = false
    config.encoding = "utf-8"
    config.load_defaults 7.0
    config.i18n.available_locales = [:en, :sk]
    config.i18n.default_locale = :en
    config.i18n.fallbacks = true

  end
end
