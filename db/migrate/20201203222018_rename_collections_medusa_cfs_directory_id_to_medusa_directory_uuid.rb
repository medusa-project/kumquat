class RenameCollectionsMedusaCfsDirectoryIdToMedusaDirectoryUuid < ActiveRecord::Migration[6.0]
  def change
    rename_column :collections, :medusa_cfs_directory_id, :medusa_directory_uuid
  end
end
