class OtpMailer < ApplicationMailer
  default from: ENV['GMAIL_USERNAME']

  def login_code(user_id, code)
    @user = User.find_by(id: user_id)
    @code = code

    return unless @user.present?

    mail(to: @user.email, subject: "Tvoj prihlasovací kód") do |format|
      format.html
      format.text
    end
  end

  # Registration code is sent before the account exists, so it takes the raw
  # email rather than a user id.
  def registration_code(email, code)
    @code = code

    mail(to: email, subject: "Tvoj registračný kód") do |format|
      format.html
      format.text
    end
  end
end
