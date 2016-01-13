class AddSortableColumnToElementDefs < ActiveRecord::Migration
  def change
    add_column :element_defs, :sortable, :boolean, default: false
    add_column :element_defs, :is_default_sort, :boolean, default: false
  end
end
