class ProductImportJob < ApplicationJob
    queue_as :product_import
  
    def perform()
        Product.import
    end
end