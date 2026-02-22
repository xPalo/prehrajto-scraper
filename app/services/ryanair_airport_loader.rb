class RyanairAirportLoader
  CACHE_KEY = "ryanair_airports"

  def self.airports
    Rails.cache.fetch(CACHE_KEY, expires_in: 2.weeks) { load_airports }
  end

  def self.load_airports
    raw_output = `python3 pyservice/ryanair_airports.py`

    JSON.parse(raw_output).map { |a| ["#{a['name']} (#{a['code']})", a['code']] }
  rescue JSON::ParserError => e
    Rails.logger.error("Airport loading failed: #{e.message}")
    []
  end
end
