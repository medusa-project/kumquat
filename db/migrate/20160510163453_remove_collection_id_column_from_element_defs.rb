class RemoveCollectionIdColumnFromElementDefs < ActiveRecord::Migration
  def change
    remove_column :element_defs, :collection_id
  end
end
