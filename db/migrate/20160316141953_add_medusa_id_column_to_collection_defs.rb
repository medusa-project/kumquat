class AddMedusaIdColumnToCollectionDefs < ActiveRecord::Migration
  def change
    add_column :collection_defs, :medusa_id, :integer
  end
end
