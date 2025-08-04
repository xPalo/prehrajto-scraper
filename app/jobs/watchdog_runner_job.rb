class WatchdogRunnerJob < ApplicationJob
  queue_as :default

  def perform
    watchdogs_to_deactivate = []

    Watchdog.where(is_active: true).group_by(&:user_id).each do |user_id, watchdogs|
      flights = []

      watchdogs.each do |watchdog|
        watchdogs_to_deactivate << watchdog.id if watchdog.date_watch_to < Date.current

        flights += RyanairFlightFetcher.fetch_flights(watchdog)
      end

      next if flights.blank?

      sorted_flights = flights.sort_by { |flight| flight['price'].to_f }
      RaincheckMailer.watchdog_email(user_id, sorted_flights).deliver_now
    end

    Watchdog.where(id: watchdogs_to_deactivate).update_all(is_active: false)
  end
end
