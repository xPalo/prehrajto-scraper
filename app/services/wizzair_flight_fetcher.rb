require 'net/http'
require 'uri'
require 'json'

class WizzairFlightFetcher
  API_VERSION_DEFAULT = '28.6.0'.freeze
  BASE_URL = 'https://be.wizzair.com'.freeze
  HOMEPAGE_URL = 'https://wizzair.com/en-gb/'.freeze
  VERSION_CACHE_KEY = 'wizzair_api_version'.freeze
  BROWSER_USER_AGENT = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) ' \
                       'AppleWebKit/537.36 (KHTML, like Gecko) ' \
                       'Chrome/122.0.0.0 Safari/537.36'.freeze

  RETRYABLE_CODES = [502, 503, 504].freeze
  RETRYABLE_ERRORS = [
    Net::OpenTimeout,
    Net::ReadTimeout,
    Errno::ECONNRESET,
    Errno::ECONNREFUSED,
    SocketError,
    OpenSSL::SSL::SSLError
  ].freeze
  MAX_ATTEMPTS = 3
  RETRY_BACKOFF_SECONDS = [2, 4].freeze

  def self.fetch_flights(watchdog)
    return [] if watchdog.to_airport.blank?

    version = api_version
    uri = URI("#{BASE_URL}/#{version}/Api/search/timetable")

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

    response = perform_request_with_retry(http, request)

    unless response.is_a?(Net::HTTPSuccess)
      code = response.code.to_i

      if code == 400 && invalid_market?(response.body)
        Rails.logger.info("Wizzair: no route #{watchdog.from_airport}→#{watchdog.to_airport}")
        return []
      end

      Rails.logger.error("Wizzair API returned #{code} (version=#{version}); body: #{response.body.to_s[0, 200]}")
      Rails.cache.delete(VERSION_CACHE_KEY) if code == 404 || code >= 500

      FetcherAlerter.notify(
        provider: 'wizzair',
        error_type: "http_#{code}",
        message: "version=#{version} route=#{watchdog.from_airport}->#{watchdog.to_airport} body=#{response.body.to_s[0, 500]}"
      )

      return []
    end

    parsed = JSON.parse(response.body)
    normalize(parsed['outboundFlights'] || [])
  rescue StandardError => e
    Rails.logger.error("Wizzair fetch failed: #{e.class}: #{e.message}")
    FetcherAlerter.notify(provider: 'wizzair', error_type: 'exception', message: "#{e.class}: #{e.message}")

    []
  end

  def self.perform_request_with_retry(http, request)
    attempt = 0
    loop do
      attempt += 1
      response = nil
      error = nil

      begin
        response = http.request(request)
      rescue *RETRYABLE_ERRORS => e
        error = e
      end

      retryable = error || (response && RETRYABLE_CODES.include?(response.code.to_i))
      return response unless retryable

      if attempt >= MAX_ATTEMPTS
        raise error if error

        return response
      end

      sleep_seconds = RETRY_BACKOFF_SECONDS[attempt - 1] || RETRY_BACKOFF_SECONDS.last
      reason = error ? "#{error.class}: #{error.message}" : "HTTP #{response.code}"
      Rails.logger.warn("Wizzair retry #{attempt}/#{MAX_ATTEMPTS - 1} after #{reason}; sleeping #{sleep_seconds}s")
      sleep(sleep_seconds)
    end
  end

  def self.api_version
    Rails.cache.fetch(VERSION_CACHE_KEY, expires_in: 6.hours, skip_nil: true) { discover_version } || API_VERSION_DEFAULT
  end

  def self.discover_version
    uri = URI(HOMEPAGE_URL)

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.open_timeout = 5
    http.read_timeout = 15

    request = Net::HTTP::Get.new(uri.request_uri, { 'User-Agent' => BROWSER_USER_AGENT })
    response = http.request(request)

    return nil unless response.is_a?(Net::HTTPSuccess)

    match = response.body.match(%r{be\.wizzair\.com(?:/|\\u002[fF])(\d+\.\d+\.\d+)(?:/|\\u002[fF])Api})
    match && match[1]
  rescue StandardError => e
    Rails.logger.error("Wizzair version discovery failed: #{e.class}: #{e.message}")
    FetcherAlerter.notify(provider: 'wizzair', error_type: 'version_discovery_failed', message: "#{e.class}: #{e.message}")

    nil
  end

  def self.invalid_market?(body)
    JSON.parse(body.to_s).dig('validationCodes')&.include?('InvalidMarket')
  rescue JSON::ParserError
    false
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
      departure = f['departureDates']&.first || f['departureDate']
      amount = f.dig('price', 'amount')
      currency = f.dig('price', 'currencyCode')
      next if departure.blank? || amount.blank? || currency.blank?

      price_eur = CurrencyConverter.to_eur(amount, currency)
      next if price_eur.nil?

      {
        'departure' => departure,
        'flight_number' => [f['carrierCode'], f['flightNumber']].compact.join(' ').strip,
        'price' => price_eur,
        'currency' => 'EUR',
        'origin' => f['departureStation'],
        'originFull' => f['departureStation'],
        'destination' => f['arrivalStation'],
        'destinationFull' => f['arrivalStation'],
        'airline' => 'Wizzair'
      }
    end
  end
end
