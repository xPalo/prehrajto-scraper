class RyanairAirportLoader
  CACHE_KEY = "ryanair_airports"
  API_URL = "https://www.ryanair.com/api/views/locate/5/airports/en/active"

  def self.airports
    Rails.cache.fetch(CACHE_KEY, expires_in: 4.weeks) { load_airports }
  end

  def self.load_airports
    response = Net::HTTP.get(URI(API_URL))
    data = JSON.parse(response)

    data.sort_by { |row| row['name'] }.map do |row|
      ["#{row['name']}, #{row.dig('country', 'name')} (#{row['code']})", row['code']]
    end
  rescue StandardError => e
    Rails.logger.error("Airport loading failed: #{e.message}")

    []
  end
end
