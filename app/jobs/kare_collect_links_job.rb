class KareCollectLinksJob < ApplicationJob
  queue_as :kare_collect_links
  sidekiq_options retry: 0

  def perform()
    Kare.update_all(status: 'new',quantity: 0)
    service = KareCollectLinks.new.call
    if service
      kares = Rails.env.development? ? Kare.order(:id).limit(100) : Kare.all.order(:id)
      kares.each_with_index do |kare, index|
        KareParsPageJob.perform_later(kare.url)
      end
    end
  end
end