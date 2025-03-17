class IdcImportJob < ApplicationJob
  queue_as :idc_import
  sidekiq_options retry: 0

  def perform
    Idc::Import.call
  end
end