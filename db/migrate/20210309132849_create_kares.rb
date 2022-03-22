class CreateKares < ActiveRecord::Migration[5.0]
  def change
    create_table :kares do |t|
      t.string :sku
      t.string :title
      t.string :full_title
      t.string :desc
      t.string :cat
      t.string :charact
      t.decimal :price
      t.integer :quantity
      t.integer :quantity_euro
      t.string :specialty
      t.string :image
      t.string :url
      t.string :brand

      t.timestamps
    end
  end
end
