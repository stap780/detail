require 'sidekiq-scheduler'

# IdcCsvFileScheduler is a Sidekiq worker responsible for scheduling the processing of IDC CSV files.
class IdcCsvFileScheduler
  include Sidekiq::Worker

  def perform
    Idc.csv_param
  end
end