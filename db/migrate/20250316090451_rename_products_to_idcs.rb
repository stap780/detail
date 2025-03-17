class RenameProductsToIdcs < ActiveRecord::Migration[7.1]
  def change
    rename_table :products, :idcs
  end
end
