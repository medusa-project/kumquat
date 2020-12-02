class RenameBinariesCfsFileUuidToMedusaUuid < ActiveRecord::Migration[6.0]
  def change
    rename_column :binaries, :cfs_file_uuid, :medusa_uuid
  end
end
