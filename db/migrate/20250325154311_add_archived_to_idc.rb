class AddArchivedToIdc < ActiveRecord::Migration[7.1]
  def change
    add_column :idcs, :archived, :boolean, default: false
  end
end
