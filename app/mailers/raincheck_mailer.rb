class RaincheckMailer < ApplicationMailer
  default from: ENV['GMAIL_USERNAME']

  def watchdog_email(user_id, sorted_flights)
    @user = User.find_by(user_id)
    @sorted_flights = sorted_flights

    mail(to: @user.email, subject: "Lacné lety dostupné!") do |format|
      format.html
    end
  end
end
