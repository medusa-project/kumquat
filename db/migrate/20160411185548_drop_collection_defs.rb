class DropCollectionDefs < ActiveRecord::Migration[4.2]
  def change
    drop_table :collection_defs
  end
end
