class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable

  has_many :favs
  has_many :watchdogs
  has_many :videos, dependent: :destroy
end
