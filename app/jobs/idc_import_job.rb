# IdcImportJob < ApplicationJob
class IdcImportJob < ApplicationJob
  queue_as :idc_import
  sidekiq_options retry: 0

  def perform
    Webshare.new.refresh_proxy_list
    # Idc::Import.call
    Idc::Sb.call
  end
end