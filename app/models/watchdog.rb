class Watchdog < ApplicationRecord
  belongs_to :user

  validates :from_airport, presence: true
  validates :user_id, presence: true
  validate :dates_valid

  def dates_valid
    return if date_watch_from <= date_watch_to

    errors.add(:date_watch_from, :invalid)
  end
end
