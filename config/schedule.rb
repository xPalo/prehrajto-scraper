set :output, "log/cron.log"
set :environment, ENV["RAILS_ENV"]

every 1.hour do
  runner "WatchdogRunnerJob.perform_later"
end
