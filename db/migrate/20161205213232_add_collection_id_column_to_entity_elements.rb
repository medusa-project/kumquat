class AddCollectionIdColumnToEntityElements < ActiveRecord::Migration
  def change
    add_column :entity_elements, :collection_id, :integer
  end
end
