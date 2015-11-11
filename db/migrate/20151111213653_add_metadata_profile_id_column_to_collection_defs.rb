class AddMetadataProfileIdColumnToCollectionDefs < ActiveRecord::Migration
  def change
    add_column :collection_defs, :metadata_profile_id, :integer
  end
end
