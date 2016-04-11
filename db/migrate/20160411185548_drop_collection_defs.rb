class DropCollectionDefs < ActiveRecord::Migration
  def change
    drop_table :collection_defs
  end
end
