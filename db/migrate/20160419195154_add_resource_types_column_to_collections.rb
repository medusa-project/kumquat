class AddResourceTypesColumnToCollections < ActiveRecord::Migration[4.2]
  def change
    add_column :collections, :resource_types, :text
  end
end
