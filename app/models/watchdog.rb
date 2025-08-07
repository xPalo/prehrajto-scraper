class Watchdog < ApplicationRecord
  KEEP_PRICE_HISTORY_FOR_MONTHS = 3

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
    date_watch_to == date_watch_from && to_airport.present?
  end
end
