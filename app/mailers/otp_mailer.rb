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
end
