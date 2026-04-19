require 'net/http'
require 'uri'
require 'json'

class WizzairFlightFetcher
  API_VERSION_DEFAULT = '20.6.0'.freeze
  BASE_URL = 'https://be.wizzair.com'.freeze
  BROWSER_USER_AGENT = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) ' \
                       'AppleWebKit/537.36 (KHTML, like Gecko) ' \
                       'Chrome/122.0.0.0 Safari/537.36'.freeze

  def self.fetch_flights(watchdog)
    return [] if watchdog.to_airport.blank?

    uri = URI("#{BASE_URL}/#{api_version}/Api/search/timetable")

    body = {
      flightList: [
        {
          departureStation: watchdog.from_airport,
          arrivalStation: watchdog.to_airport,
          from: watchdog.date_watch_from.strftime('%Y-%m-%d'),
          to: watchdog.date_watch_to.strftime('%Y-%m-%d')
        }
      ],
      priceType: 'regular',
      adultCount: 1,
      childCount: 0,
      infantCount: 0
    }

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 5
    http.read_timeout = 15

    request = Net::HTTP::Post.new(uri.request_uri, request_headers)
    request.body = body.to_json

    response = http.request(request)

    unless response.is_a?(Net::HTTPSuccess)
      Rails.logger.error("Wizzair API returned #{response.code} (version=#{api_version}); body: #{response.body.to_s[0, 500]}")

      return []
    end

    parsed = JSON.parse(response.body)
    normalize(parsed['outboundFlights'] || [])
  rescue StandardError => e
    Rails.logger.error("Wizzair fetch failed: #{e.class}: #{e.message}")
    []
  end

  def self.api_version
    ENV.fetch('WIZZAIR_API_VERSION', API_VERSION_DEFAULT)
  end

  def self.request_headers
    {
      'Content-Type' => 'application/json;charset=UTF-8',
      'Accept' => 'application/json, text/plain, */*',
      'User-Agent' => BROWSER_USER_AGENT,
      'Referer' => 'https://wizzair.com/',
      'Origin' => 'https://wizzair.com'
    }
  end

  def self.normalize(flights)
    flights.filter_map do |f|
      departure = f['departureDate'] || f['departureDates']&.first
      price = f.dig('price', 'amount')
      next if departure.blank? || price.blank?

      {
        'departure' => departure,
        'flight_number' => [f['carrierCode'], f['flightNumber']].compact.join(' ').strip,
        'price' => price,
        'currency' => f.dig('price', 'currencyCode') || 'EUR',
        'origin' => f['departureStation'],
        'originFull' => f['departureStation'],
        'destination' => f['arrivalStation'],
        'destinationFull' => f['arrivalStation'],
        'airline' => 'Wizzair'
      }
    end
  end
end
