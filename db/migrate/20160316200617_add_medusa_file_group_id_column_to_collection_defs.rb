class AddMedusaFileGroupIdColumnToCollectionDefs < ActiveRecord::Migration
  def change
    add_column :collection_defs, :medusa_file_group_id, :integer
  end
end
