class RemoveObsoleteCollectionsResourceTypesAndAccessSystemsColumns < ActiveRecord::Migration[7.1]
  def change
    remove_column :collections, :access_systems_deleteme
    remove_column :collections, :resource_types_deleteme
  end
end
