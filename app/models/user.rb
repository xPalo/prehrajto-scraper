class User < ApplicationRecord
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable

  has_many :favs
  has_many :watchdogs
  has_many :videos, dependent: :destroy

  OTP_VALIDITY = 10.minutes

  # A fresh 6-digit code, zero-padded. Returned in plaintext to be emailed.
  def self.generate_otp_code
    format("%06d", SecureRandom.random_number(1_000_000))
  end

  def self.otp_digest(code)
    Digest::SHA256.hexdigest(code.to_s)
  end

  # Constant-time check of a submitted code against a stored digest + timestamp.
  # The digest/sent_at can come from a persisted row (login) or from the session
  # (a pending OTP registration where no row exists yet).
  def self.otp_valid?(digest, sent_at, submitted)
    return false if digest.blank? || sent_at.blank?
    return false if sent_at < OTP_VALIDITY.ago

    Devise.secure_compare(digest, otp_digest(submitted))
  end

  # Generates a fresh 6-digit login code, stores only its digest, and returns
  # the plaintext so the caller can email it. The plaintext is never persisted.
  def generate_otp!
    code = self.class.generate_otp_code
    update!(otp_code_digest: self.class.otp_digest(code), otp_sent_at: Time.current)
    code
  end

  def verify_otp(submitted)
    self.class.otp_valid?(otp_code_digest, otp_sent_at, submitted)
  end

  def clear_otp!
    update!(otp_code_digest: nil, otp_sent_at: nil)
  end

  # Devise delivers its notifications (password reset, password/email change)
  # synchronously by default, which blocks the request on the slow Gmail SMTP
  # handshake — the reset form would hang in the browser until the send
  # finished. Enqueue through Active Job / Sidekiq instead, matching the rest
  # of the app (OtpMailer, FetcherAlertMailer all use deliver_later).
  def send_devise_notification(notification, *args)
    devise_mailer.send(notification, self, *args).deliver_later
  end
end
