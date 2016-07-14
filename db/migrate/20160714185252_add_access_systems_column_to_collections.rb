class AddAccessSystemsColumnToCollections < ActiveRecord::Migration
  def change
    add_column :collections, :access_systems, :text
  end
end
