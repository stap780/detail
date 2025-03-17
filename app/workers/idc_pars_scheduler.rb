require 'sidekiq-scheduler'

# IdcParsScheduler is a Sidekiq worker responsible for
class IdcParsScheduler
  include Sidekiq::Worker

  def perform
    Idc::Import.call
  end
end