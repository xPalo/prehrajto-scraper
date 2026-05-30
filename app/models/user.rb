class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable

  has_many :favs
  has_many :watchdogs
  has_many :videos, dependent: :destroy

  OTP_VALIDITY = 10.minutes

  # Generates a fresh 6-digit login code, stores only its digest, and returns
  # the plaintext so the caller can email it. The plaintext is never persisted.
  def generate_otp!
    code = format("%06d", SecureRandom.random_number(1_000_000))
    update!(otp_code_digest: Digest::SHA256.hexdigest(code), otp_sent_at: Time.current)
    code
  end

  def verify_otp(submitted)
    return false if otp_code_digest.blank? || otp_sent_at.blank?
    return false if otp_sent_at < OTP_VALIDITY.ago

    Devise.secure_compare(otp_code_digest, Digest::SHA256.hexdigest(submitted.to_s))
  end

  def clear_otp!
    update!(otp_code_digest: nil, otp_sent_at: nil)
  end
end
