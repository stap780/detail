require 'sidekiq-scheduler'

# LogFilesScheduler is a Sidekiq worker responsible for scheduling the creation of log file zips.
class LogFilesScheduler
  include Sidekiq::Worker

  def perform
    Rails.application.load_tasks
    Rake::Task['file:create_log_zip_every_day'].invoke
  end
end