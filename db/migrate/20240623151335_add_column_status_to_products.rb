class AddColumnStatusToProducts < ActiveRecord::Migration[7.1]
  def change
    add_column :products, :status, :string, default: 'new', null: false
  end
end
