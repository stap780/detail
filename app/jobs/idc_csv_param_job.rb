# IdcCsvParamJob is a background job that enqueues tasks to process IDC CSV parameters.
class IdcCsvParamJob < ApplicationJob
  queue_as :idc_csv_param

  def perform()
    Idc.csv_param
  end

end