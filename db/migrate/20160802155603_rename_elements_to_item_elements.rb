class RenameElementsToItemElements < ActiveRecord::Migration
  def change
    rename_table :elements, :item_elements
  end
end
