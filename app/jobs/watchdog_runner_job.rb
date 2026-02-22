class WatchdogRunnerJob < ApplicationJob
  queue_as :default

  def perform
    watchdogs_to_deactivate = []

    Watchdog.where(is_active: true).group_by(&:user_id).each do |user_id, watchdogs|
      flights = []
      price_changed = false

      watchdogs.each do |watchdog|
        watchdogs_to_deactivate << watchdog.id if watchdog.date_watch_to < Date.current
        fetched_flights = RyanairFlightFetcher.fetch_flights(watchdog, skip_price_arg: true)

        if watchdog.can_analyze_price? && fetched_flights.present?
          current_price = fetched_flights.first['price'].to_f.round(2)
          last_price = watchdog.price_history.last&.dig('y')&.to_f&.round(2)
          price_changed = true if last_price.nil? || last_price != current_price

          keep_from_date = Watchdog::KEEP_PRICE_HISTORY_FOR_MONTHS.months.ago.iso8601
          new_price_point = {
            'x' => Time.current.iso8601,
            'y' => current_price
          }

          watchdog.price_history = (watchdog.price_history + [new_price_point])
                                     .select { |point| point['x'] >= keep_from_date }
                                     .sort_by { |point| point['x'] }
        end

        watchdog.save if watchdog.changed?

        fetched_flights.filter! { |flight| flight['price'].to_f <= watchdog.max_price } if watchdog.max_price.present?

        flights += fetched_flights
      end

      next if flights.blank? || !price_changed

      sorted_flights = flights.sort_by { |flight| flight['price'].to_f }
      RaincheckMailer.watchdog_email(user_id, sorted_flights).deliver_now
    end

    Watchdog.where(id: watchdogs_to_deactivate).update_all(is_active: false)
  end
end
