class CollectionsDefaultToNotHarvestable < ActiveRecord::Migration
  def change
    change_column :collections, :harvestable, :boolean, default: false
  end
end
