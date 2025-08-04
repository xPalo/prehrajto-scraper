class RyanairFlightFetcher
  attr_reader :watchdogs

  def self.fetch_flights(watchdog)
    cmd = %w(python3 pyservice/ryanair_fetch.py)

    cmd << "--from" << watchdog.from_airport
    cmd << "--date-from" << watchdog.date_watch_from.strftime("%Y-%m-%d")
    cmd << "--date-to" << watchdog.date_watch_to.strftime("%Y-%m-%d")

    cmd << "--to-country" << watchdog.to_country if watchdog.to_country.present?
    cmd << "--to-airport" << watchdog.to_airport if watchdog.to_airport.present?
    cmd << "--departure-time-from" << watchdog.departure_time_from.strftime("%Y-%m-%d") if watchdog.departure_time_from.present?
    cmd << "--departure-time-to" << watchdog.departure_time_to.strftime("%Y-%m-%d") if watchdog.departure_time_to.present?
    cmd << "--max-price" << watchdog.max_price.to_s if watchdog.max_price.present?

    raw_output = `#{cmd.shelljoin}`

    begin
      JSON.parse(raw_output)
    rescue JSON::ParserError => e
      Rails.logger.error("Python script failed: #{e.message}")

      []
    end
  end
end