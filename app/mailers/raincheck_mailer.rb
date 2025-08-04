class RaincheckMailer < ApplicationMailer
  default from: ENV['GMAIL_USERNAME']

  def watchdog_email(user_id, sorted_flights)
    @user = User.find_by(id: user_id)
    @sorted_flights = sorted_flights

    return unless @user.present?

    mail(to: @user.email, subject: "Lacné lety dostupné!") do |format|
      format.html
    end
  end
end
