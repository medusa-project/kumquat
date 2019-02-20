class AddDcMapColumnsToElementDefs < ActiveRecord::Migration[4.2]
  def change
    add_column :element_defs, :dc_map, :string
    add_column :element_defs, :dcterms_map, :string
  end
end
