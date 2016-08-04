class RenameAvailableElementsToElements < ActiveRecord::Migration
  def change
    rename_table :available_elements, :elements
  end
end
