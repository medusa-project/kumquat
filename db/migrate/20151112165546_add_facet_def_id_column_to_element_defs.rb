class AddFacetDefIdColumnToElementDefs < ActiveRecord::Migration
  def change
    add_column :element_defs, :facet_def_id, :integer
  end
end
