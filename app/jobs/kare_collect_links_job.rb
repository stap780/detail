class KareCollectLinksJob < ApplicationJob
  queue_as :kare_collect_links
  sidekiq_options retry: 0

  def perform()
    Webshare.new.refresh_proxy_list
    Kare.update_all(status: 'new',quantity: 0)
    service = KareCollectLinks.call
    if service
      kares = Rails.env.development? ? Kare.order(:id).limit(100) : Kare.all.order(:id)
      kares.each do |kare|
        KareParsPageJob.perform_later(kare.url)
      end
    end
  end
end