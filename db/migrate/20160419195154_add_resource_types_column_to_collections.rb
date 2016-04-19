class AddResourceTypesColumnToCollections < ActiveRecord::Migration
  def change
    add_column :collections, :resource_types, :text
  end
end
