class AddMetadataFileGroupToCollectionDefs < ActiveRecord::Migration[4.2]
  def change
    add_column :collection_defs, :medusa_metadata_file_group_id, :integer
    rename_column :collection_defs, :medusa_file_group_id, :medusa_data_file_group_id
  end
end
