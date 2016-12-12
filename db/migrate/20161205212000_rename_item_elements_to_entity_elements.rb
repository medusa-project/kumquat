class RenameItemElementsToEntityElements < ActiveRecord::Migration

  def up
    rename_table :item_elements, :entity_elements
    add_column :entity_elements, :type, :string
  end

  def down
    rename_table :entity_elements, :item_elements
    remove_column :item_elements, :type
  end

end
