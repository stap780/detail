json.extract! product, :id, :sku, :title, :desc, :cat, :charact, :charact_gab, :oldprice, :price, :quantity, :image, :url, :created_at, :updated_at
json.url product_url(product, format: :json)
