class AddMetadataProfileIdColumnToCollectionDefs < ActiveRecord::Migration[4.2]
  def change
    add_column :collection_defs, :metadata_profile_id, :integer
  end
end
