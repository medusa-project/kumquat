class AddLastIndexedColumnToCollections < ActiveRecord::Migration
  def change
    add_column :collections, :last_indexed, :datetime
  end
end
