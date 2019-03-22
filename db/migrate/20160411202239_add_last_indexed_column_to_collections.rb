class AddLastIndexedColumnToCollections < ActiveRecord::Migration[4.2]
  def change
    add_column :collections, :last_indexed, :datetime
  end
end
