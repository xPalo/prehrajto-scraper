class WatchdogRunnerWorker
  include Sidekiq::Worker

  def perform
    WatchdogRunnerJob.perform_later
  end
end