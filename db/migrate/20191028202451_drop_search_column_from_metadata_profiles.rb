class DropSearchColumnFromMetadataProfiles < ActiveRecord::Migration[5.2]
  def change
    if column_exists? :metadata_profiles, :search
      remove_column :metadata_profiles, :search
    end
  end
end
