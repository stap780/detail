require 'sidekiq-scheduler'

# KareCsvFileScheduler is a Sidekiq worker responsible for scheduling CSV file operations.
class KareCsvFileScheduler
  include Sidekiq::Worker

  def perform
    Kare.csv_param
  end

end