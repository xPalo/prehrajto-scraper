class RaincheckMailer < ApplicationMailer
  default from: ENV['GMAIL_USERNAME']

  def watchdog_email(user_id, sorted_flights)
    @user = User.find_by(id: user_id)
    @sorted_flights = sorted_flights

    return unless @user.present?

    watchdog_ids = sorted_flights.filter_map { |f| f['watchdog_id'] }.uniq
    @deactivate_tokens = Watchdog.where(id: watchdog_ids).each_with_object({}) do |watchdog, hash|
      hash[watchdog.id] = watchdog.deactivation_token
    end

    mail(to: @user.email, subject: "Lacné lety dostupné!") do |format|
      format.html
    end
  end
end
