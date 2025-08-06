class WatchdogRunnerJob < ApplicationJob
  queue_as :default

  def perform
    watchdogs_to_deactivate = []

    Watchdog.where(is_active: true).group_by(&:user_id).each do |user_id, watchdogs|
      flights = []

      watchdogs.each do |watchdog|
        watchdogs_to_deactivate << watchdog.id if watchdog.date_watch_to < Date.current
        fetched_flights = RyanairFlightFetcher.fetch_flights(watchdog, skip_price_arg: true)

        if watchdog.can_analyze_price? && fetched_flights.present?
          keep_from_date = Watchdog::KEEP_PRICE_HISTORY_FOR_MONTHS.months.ago.iso8601
          new_price_point = {
            'x' => Time.current.iso8601,
            'y' => fetched_flights.first['price'].to_f
          }

          watchdog.price_history = (watchdog.price_history + [new_price_point])
                                     .select { |point| point['x'] >= keep_from_date }
                                     .sort_by { |point| point['x'] }
          watchdog.save
        end

        fetched_flights.filter! { |flight| flight['price'].to_f <= watchdog.max_price } if watchdog.max_price.present?

        flights += fetched_flights
      end

      next if flights.blank?

      sorted_flights = flights.sort_by { |flight| flight['price'].to_f }
      RaincheckMailer.watchdog_email(user_id, sorted_flights).deliver_now
    end

    Watchdog.where(id: watchdogs_to_deactivate).update_all(is_active: false)
  end
end
