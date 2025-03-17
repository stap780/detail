class IdcParsUrlJob < ApplicationJob
  queue_as :idc_pars_url
  sidekiq_options retry: 0

  def perform(url)
    Idc::ParsUrl.call(url)
  end

end