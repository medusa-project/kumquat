class RemoveItemsFullText < ActiveRecord::Migration[4.2]
  def change
    remove_column :items, :full_text
  end
end
