class CollectionsDefaultToNotHarvestable < ActiveRecord::Migration[4.2]
  def change
    change_column :collections, :harvestable, :boolean, default: false
  end
end
