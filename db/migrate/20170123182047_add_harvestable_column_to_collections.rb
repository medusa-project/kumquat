class AddHarvestableColumnToCollections < ActiveRecord::Migration[4.2]
  def change
    add_column :collections, :harvestable, :boolean, default: true
  end
end
