class RenameContentProfilesToPackageProfiles < ActiveRecord::Migration
  def change
    rename_column :collections, :content_profile_id, :package_profile_id
  end
end
