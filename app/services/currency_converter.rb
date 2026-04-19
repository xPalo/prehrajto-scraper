require 'net/http'
require 'uri'
require 'json'

class CurrencyConverter
  FX_URL = 'https://api.frankfurter.dev/v1/latest'.freeze

  def self.to_eur(amount, currency)
    return amount.to_f.round(2) if currency == 'EUR'

    rate = eur_rate(currency)
    return nil if rate.nil?

    (amount.to_f * rate).round(2)
  end

  def self.eur_rate(currency)
    Rails.cache.fetch("fx_#{currency}_to_eur", expires_in: 12.hours) do
      uri = URI("#{FX_URL}?base=#{currency}&symbols=EUR")
      response = Net::HTTP.get_response(uri)

      unless response.is_a?(Net::HTTPSuccess)
        Rails.logger.error("Frankfurter returned #{response.code} for #{currency}→EUR")
        next nil
      end

      JSON.parse(response.body).dig('rates', 'EUR')
    end
  rescue StandardError => e
    Rails.logger.error("Frankfurter fetch failed: #{e.class}: #{e.message}")
    nil
  end
end
