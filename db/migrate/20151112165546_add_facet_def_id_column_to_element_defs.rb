class AddFacetDefIdColumnToElementDefs < ActiveRecord::Migration[4.2]
  def change
    add_column :element_defs, :facet_def_id, :integer
    add_column :element_defs, :facet_def_label, :string
  end
end
