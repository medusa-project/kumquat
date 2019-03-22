class AddMedusaCfsDirectoryIdColumnToCollections < ActiveRecord::Migration[4.2]
  def change
    add_column :collections, :medusa_cfs_directory_id, :integer
  end
end
