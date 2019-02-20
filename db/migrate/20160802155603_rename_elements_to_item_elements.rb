class RenameElementsToItemElements < ActiveRecord::Migration[4.2]
  def change
    rename_table :elements, :item_elements
  end
end
