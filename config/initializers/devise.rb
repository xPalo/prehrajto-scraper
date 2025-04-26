Devise.setup do |config|
  require 'devise/orm/active_record'

  config.navigational_formats = ['*/*', :html, :turbo_stream]
  config.mailer_sender = 'adam.palo222@gmail.com'
  config.case_insensitive_keys = [:email]
  config.strip_whitespace_keys = [:email]
  config.skip_session_storage = [:http_auth]
  config.stretches = Rails.env.test? ? 1 : 12
  config.reconfirmable = true
  config.expire_all_remember_me_on_sign_out = true
  config.password_length = 6..128
  config.email_regexp = /\A[^@\s]+@[^@\s]+\z/
  config.reset_password_within = 6.hours
  config.sign_out_via = :delete
  config.parent_controller = 'ApplicationController'
  # config.mailer.default_url_options = { host: '62.65.160.178', port: 46580, protocol: 'http' }
end
