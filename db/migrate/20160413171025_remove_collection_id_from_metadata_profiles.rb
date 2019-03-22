class RemoveCollectionIdFromMetadataProfiles < ActiveRecord::Migration[4.2]
  def change
    remove_column :metadata_profiles, :collection_id
  end
end
