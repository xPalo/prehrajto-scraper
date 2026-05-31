Devise.setup do |config|
  require 'devise/orm/active_record'

  config.navigational_formats = ['*/*', :html]
  # Send Devise mail from the same Gmail account the SMTP settings authenticate
  # with (see config/environments/production.rb), so the From header isn't
  # rewritten/rejected. Falls back to the literal address in non-prod.
  config.mailer_sender = ENV.fetch("GMAIL_USERNAME", "adam.palo222@gmail.com")
  config.case_insensitive_keys = [:email]
  config.strip_whitespace_keys = [:email]
  config.skip_session_storage = [:http_auth]
  config.stretches = Rails.env.test? ? 1 : 12
  config.reconfirmable = true
  config.remember_for = 3.months
  config.extend_remember_period = true
  config.expire_all_remember_me_on_sign_out = true
  config.password_length = 6..128
  config.email_regexp = /\A[^@\s]+@[^@\s]+\z/
  config.reset_password_within = 6.hours
  # Notify users by email when their password or email address changes.
  config.send_password_change_notification = true
  config.send_email_changed_notification = true
  config.sign_out_via = :delete
  config.parent_controller = 'ApplicationController'
  # config.mailer.default_url_options = { host: '62.65.160.178', port: 46580, protocol: 'http' }
end
