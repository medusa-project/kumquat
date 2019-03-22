class RemoveFacetDefs < ActiveRecord::Migration[4.2]
  def change
    remove_column :element_defs, :facet_def_id
    drop_table :facet_defs
  end
end
