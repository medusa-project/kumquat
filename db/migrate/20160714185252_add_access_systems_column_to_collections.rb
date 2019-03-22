class AddAccessSystemsColumnToCollections < ActiveRecord::Migration[4.2]
  def change
    add_column :collections, :access_systems, :text
  end
end
