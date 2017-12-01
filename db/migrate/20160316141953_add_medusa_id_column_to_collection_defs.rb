class AddMedusaIdColumnToCollectionDefs < ActiveRecord::Migration[4.2]
  def change
    add_column :collection_defs, :medusa_id, :integer
  end
end
