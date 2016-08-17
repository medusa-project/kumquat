class AddMedusaRepositoryIdColumnToCollections < ActiveRecord::Migration
  def change
    add_column :collections, :medusa_repository_id, :integer
  end
end
