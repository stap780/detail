class KareCollectLinksJob < ApplicationJob
    queue_as :kare_collect_links
  
    def perform()
        Kare.update_all(status: 'new')
        service = KareCollectLinks.new.call
        if service
            Kare.order(:id).limit(100).each_with_index do |kare, index|
                proxy = Kare::Proxy[index.to_s.split('').last.to_i]
                KareParsPageJob.perform_later(kare.url, proxy)
                # KareParsPage.new(kare.url, proxy).call
            end
        end
    end
end