class AddIndexOnEntityElementsNameColumn < ActiveRecord::Migration[4.2]
  def change
    add_index :entity_elements, :name
  end
end
