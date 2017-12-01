class ChangeTypesOfCollectionColumns < ActiveRecord::Migration[4.2]
  def change
    change_column :collections, :medusa_cfs_directory_id, :string
    change_column :collections, :medusa_file_group_id, :string
  end
end
