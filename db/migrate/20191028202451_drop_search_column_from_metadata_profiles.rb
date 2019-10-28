class DropSearchColumnFromMetadataProfiles < ActiveRecord::Migration[5.2]
  def change
    remove_column :metadata_profiles, :search
  end
end
