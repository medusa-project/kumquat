class AddCollectionIdColumnToEntityElements < ActiveRecord::Migration[4.2]
  def change
    add_column :entity_elements, :collection_id, :integer
  end
end
