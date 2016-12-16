class AddIndexOnEntityElementsNameColumn < ActiveRecord::Migration
  def change
    add_index :entity_elements, :name
  end
end
