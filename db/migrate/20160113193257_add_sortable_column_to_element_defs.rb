class AddSortableColumnToElementDefs < ActiveRecord::Migration[4.2]
  def change
    add_column :element_defs, :sortable, :boolean, default: false
    add_column :element_defs, :is_default_sort, :boolean, default: false
  end
end
