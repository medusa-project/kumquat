class RemoveCollectionIdColumnFromElementDefs < ActiveRecord::Migration[4.2]
  def change
    remove_column :element_defs, :collection_id
  end
end
