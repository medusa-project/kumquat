class AddSystemSpecificHarvestableColumnsOnCollection < ActiveRecord::Migration[6.0]
  def up
    add_column :collections, :harvestable_by_idhh, :boolean, default: false, null: false
    add_column :collections, :harvestable_by_primo, :boolean, default: false, null: false
    add_index :collections, :harvestable_by_idhh
    add_index :collections, :harvestable_by_primo

    execute 'update collections set harvestable = false where harvestable is null;'
    execute 'update collections set harvestable_by_idhh = harvestable;'
    execute 'update collections set harvestable_by_primo = harvestable;'

    change_column :collections, :harvestable, :boolean, default: false, null: false
  end
  def down
    change_column :collections, :harvestable, :boolean, default: false, null: true
    remove_column :collections, :harvestable_by_idhh
    remove_column :collections, :harvestable_by_primo
  end
end
