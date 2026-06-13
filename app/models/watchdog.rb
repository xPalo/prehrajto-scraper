class Watchdog < ApplicationRecord
  KEEP_PRICE_HISTORY_FOR_MONTHS = 3

  DEACTIVATE_TOKEN_PURPOSE = "watchdog_deactivate"
  DEACTIVATE_TOKEN_EXPIRY  = 30.days

  belongs_to :user

  validates :from_airport, presence: true
  validates :date_watch_from, presence: true
  validates :date_watch_to, presence: true
  validates :user_id, presence: true
  validate :dates_valid

  def dates_valid
    return if date_watch_from <= date_watch_to

    errors.add(:date_watch_from, :invalid)
  end

  def can_analyze_price?
    to_airport.present?
  end

  # Signed, expiring token used for the one-click "deactivate" link in
  # watchdog emails — lets a logged-out recipient deactivate without auth.
  def deactivation_token
    signed_id(purpose: DEACTIVATE_TOKEN_PURPOSE, expires_in: DEACTIVATE_TOKEN_EXPIRY)
  end

  # Returns nil for an invalid/expired token or a deleted record.
  def self.find_by_deactivation_token(token)
    find_signed(token, purpose: DEACTIVATE_TOKEN_PURPOSE)
  end
end
