class AddMedusaRepositoryIdColumnToCollections < ActiveRecord::Migration[4.2]
  def change
    add_column :collections, :medusa_repository_id, :integer
  end
end
