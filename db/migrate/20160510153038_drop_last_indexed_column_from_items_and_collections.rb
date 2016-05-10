class DropLastIndexedColumnFromItemsAndCollections < ActiveRecord::Migration
  def change
    remove_column :items, :last_indexed
    remove_column :collections, :last_indexed
  end
end
