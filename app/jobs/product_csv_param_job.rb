class ProductCsvParamJob < ApplicationJob
    queue_as :product_csv_param
  
    def perform()
        Product.csv_param
    end
end