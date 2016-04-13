class RemoveCollectionIdFromMetadataProfiles < ActiveRecord::Migration
  def change
    remove_column :metadata_profiles, :collection_id
  end
end
