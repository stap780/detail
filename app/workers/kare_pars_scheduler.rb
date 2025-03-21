require 'sidekiq-scheduler'

# KareParsScheduler is a Sidekiq worker responsible for performing background jobs.
class KareParsScheduler
  include Sidekiq::Worker

  def perform
    KareCollectLinksJob.perform_later
  end
end