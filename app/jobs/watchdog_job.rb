class WatchdogJob < ApplicationJob
  queue_as :default

  def perform
    # TODO
    sorted_flights = SomeFlightFetcherService.call
    return if sorted_flights.blank?

    RaincheckMailer.email(user, sorted_flights).deliver_now
  end
end
