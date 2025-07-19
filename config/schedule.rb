set :output, "log/cron.log"
set :environment, ENV["RAILS_ENV"]

every 1.day, at: ["6:00 am", "2:00 pm", "10:00 pm"] do
  runner "WatchdogJob.perform_later"
end
