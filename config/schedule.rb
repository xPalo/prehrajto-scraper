job_type :runner, "cd :path && bundle exec rails runner -e :environment ':task'"

set :output, "log/cron.log"
set :environment, ENV["RAILS_ENV"]

every 15.minutes do
  runner "WatchdogRunnerJob.perform_now"
end