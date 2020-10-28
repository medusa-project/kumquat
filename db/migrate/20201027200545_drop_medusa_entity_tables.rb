class DropMedusaEntityTables < ActiveRecord::Migration[6.0]
  def change
    drop_table :medusa_cfs_files
    drop_table :medusa_cfs_directories
    drop_table :medusa_file_groups
    drop_table :medusa_repositories
  end
end
