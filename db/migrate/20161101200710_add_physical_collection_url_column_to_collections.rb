class AddPhysicalCollectionUrlColumnToCollections < ActiveRecord::Migration[4.2]
  def change
    add_column :collections, :physical_collection_url, :string
  end
end
