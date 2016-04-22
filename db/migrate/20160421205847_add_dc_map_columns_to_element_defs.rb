class AddDcMapColumnsToElementDefs < ActiveRecord::Migration
  def change
    add_column :element_defs, :dc_map, :string
    add_column :element_defs, :dcterms_map, :string
  end
end
