class AddStatusColumnToKares < ActiveRecord::Migration[5.0]
  def change
    add_column :kares, :status, :string, default: 'new', null: false
  end
end
