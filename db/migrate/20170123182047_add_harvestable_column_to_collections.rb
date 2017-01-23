class AddHarvestableColumnToCollections < ActiveRecord::Migration
  def change
    add_column :collections, :harvestable, :boolean, default: true
  end
end
