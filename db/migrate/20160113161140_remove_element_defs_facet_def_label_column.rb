class RemoveElementDefsFacetDefLabelColumn < ActiveRecord::Migration
  def change
    remove_column :element_defs, :facet_def_label
  end
end
