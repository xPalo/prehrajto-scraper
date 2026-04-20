class FetcherAlertMailer < ApplicationMailer
  default from: ENV['GMAIL_USERNAME']

  def failure_alert(admin_emails, provider, error_type, message)
    @provider = provider
    @error_type = error_type
    @message = message
    @host = ENV['PRODUCTION_URL'].presence || 'localhost'

    mail(bcc: admin_emails, subject: "[Watchdog] #{provider} fetcher failed (#{error_type})") do |format|
      format.html
    end
  end
end
