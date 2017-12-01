class DropLastIndexedColumnFromItemsAndCollections < ActiveRecord::Migration[4.2]
  def change
    remove_column :items, :last_indexed
    remove_column :collections, :last_indexed
  end
end
