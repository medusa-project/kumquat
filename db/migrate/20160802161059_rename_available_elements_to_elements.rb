class RenameAvailableElementsToElements < ActiveRecord::Migration[4.2]
  def change
    rename_table :available_elements, :elements
  end
end
