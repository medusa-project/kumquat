class RenameCollectionsMedusaFileGroupIdColumnToMedusaFileGroupUuid < ActiveRecord::Migration[6.1]
  def change
    rename_column :collections, :medusa_file_group_id, :medusa_file_group_uuid
  end
end
