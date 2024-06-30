class KareParsPageJob < ApplicationJob
  queue_as :kare_pars_page

  def perform(link, proxy)
    KareParsPage.new(link, proxy).call
  end
end
