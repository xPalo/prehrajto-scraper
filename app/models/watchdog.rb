class Watchdog < ApplicationRecord
  belongs_to :user

  validates :from_airport, presence: true
  validates :user_id, presence: true
  validates :is_active, presence: true
end
