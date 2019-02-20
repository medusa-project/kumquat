class RenameContentProfilesToPackageProfiles < ActiveRecord::Migration[4.2]
  def change
    rename_column :collections, :content_profile_id, :package_profile_id
  end
end
