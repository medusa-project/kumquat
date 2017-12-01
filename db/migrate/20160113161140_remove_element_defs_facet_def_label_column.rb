class RemoveElementDefsFacetDefLabelColumn < ActiveRecord::Migration[4.2]
  def change
    remove_column :element_defs, :facet_def_label
  end
end
