require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.cache_classes = true
  config.eager_load = true
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true
  config.active_storage.service = :local
  config.log_level = :info
  config.log_tags = [ :request_id ]
  config.i18n.fallbacks = true
  config.active_support.report_deprecations = false
  config.log_formatter = ::Logger::Formatter.new

  config.public_file_server.enabled = true
  config.assets.compile = false
  config.assets.digest = true
  config.force_ssl = false

  if ENV["RAILS_LOG_TO_STDOUT"].present?
    logger           = ActiveSupport::Logger.new(STDOUT)
    logger.formatter = config.log_formatter
    config.logger    = ActiveSupport::TaggedLogging.new(logger)
  end

  config.hosts << "localhost"
  config.hosts << "62.65.160.178"
  config.action_controller.default_url_options = {
    host: "62.65.160.178",
    protocol: "http",
    port: 46580
  }
  
  config.action_dispatch.trusted_proxies = [
    IPAddr.new("127.0.0.1"),
    IPAddr.new("::1"),
    IPAddr.new("62.65.160.178")
  ]
  config.active_record.sqlite3_production_warning=false
  config.active_record.dump_schema_after_migration = false

  config.action_mailer.perform_caching = false
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    address: 'smtp.gmail.com',
    port: 587,
    domain: 'gmail.com',
    user_name: ENV['GMAIL_USERNAME'],
    password: ENV['GMAIL_PASSWORD'],
    authentication: 'plain',
    enable_starttls_auto: true
  }

  config.action_mailer.default_url_options = {
    host: '62.65.160.178',
    port: 46580,
    protocol: 'http'
  }

  config.active_job.queue_adapter = :sidekiq
end

Rails.application.routes.default_url_options = {
  host: '62.65.160.178',
  port: 46580,
  protocol: 'http'
}
