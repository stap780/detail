class KareParsPageJob < ApplicationJob
  queue_as :kare_pars_page
  sidekiq_options retry: 0

  def perform(link)
    KareParsPage.new(link).call
  end
end
