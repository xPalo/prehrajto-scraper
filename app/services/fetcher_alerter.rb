class FetcherAlerter
  DEDUP_TTL = 1.hour

  def self.notify(provider:, error_type:, message:)
    cache_key = "fetcher_alert_#{provider}_#{error_type}"
    return if Rails.cache.exist?(cache_key)

    Rails.cache.write(cache_key, true, expires_in: DEDUP_TTL)

    emails = User.where(is_admin: true).pluck(:email)
    return if emails.empty?

    FetcherAlertMailer.failure_alert(emails, provider, error_type, message).deliver_later
  rescue StandardError => e
    Rails.logger.error("FetcherAlerter.notify failed: #{e.class}: #{e.message}")
  end
end
