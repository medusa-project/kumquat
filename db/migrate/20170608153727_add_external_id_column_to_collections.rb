class AddExternalIdColumnToCollections < ActiveRecord::Migration[4.2]
  def change
    add_column :collections, :external_id, :string
    add_index :collections, :external_id
  end
end
