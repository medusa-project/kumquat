class AddUniqueIndexesOnItemSetsJoinTables < ActiveRecord::Migration[5.1]
  def change
    remove_index :item_sets_users, :item_set_id
    remove_index :item_sets_users, :user_id

    add_index :item_sets_items, [:item_set_id, :item_id], unique: true
    add_index :item_sets_users, [:item_set_id, :user_id], unique: true
  end
end
