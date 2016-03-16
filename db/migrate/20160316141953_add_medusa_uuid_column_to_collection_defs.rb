class AddMedusaUuidColumnToCollectionDefs < ActiveRecord::Migration
  def change
    add_column :collection_defs, :medusa_uuid, :string
  end
end
