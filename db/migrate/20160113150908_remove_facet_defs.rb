class RemoveFacetDefs < ActiveRecord::Migration
  def change
    remove_column :element_defs, :facet_def_id
    drop_table :facet_defs
  end
end
