class RemoveItemsFullText < ActiveRecord::Migration
  def change
    remove_column :items, :full_text
  end
end
