require 'sidekiq-scheduler'

# IdcParsScheduler is a Sidekiq worker responsible for
class IdcParsScheduler
  include Sidekiq::Worker

  def perform
    IdcImportJob.perform_later
  end
end