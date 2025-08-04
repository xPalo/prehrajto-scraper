Sidekiq.configure_server do |config|
  config.redis = { url: ENV["REDIS_URL"] }

  Sidekiq::Cron::Job.load_from_hash!({
    'watchdog_runner' => {
      'class' => 'WatchdogRunnerWorker',
      'cron'  => '0 * * * *'
    }
  })
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV["REDIS_URL"] }
end
