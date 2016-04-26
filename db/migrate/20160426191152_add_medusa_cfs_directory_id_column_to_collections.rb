class AddMedusaCfsDirectoryIdColumnToCollections < ActiveRecord::Migration
  def change
    add_column :collections, :medusa_cfs_directory_id, :integer
  end
end
