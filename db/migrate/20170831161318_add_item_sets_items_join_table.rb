class AddItemSetsItemsJoinTable < ActiveRecord::Migration[4.2]
  def change
    create_table :item_sets_items do |t|
      t.integer :item_set_id
      t.integer :item_id
    end

    add_foreign_key :item_sets_items, :item_sets, on_update: :cascade, on_delete: :cascade
    add_foreign_key :item_sets_items, :items, on_update: :cascade, on_delete: :cascade
    add_foreign_key :item_sets_users, :item_sets, on_update: :cascade, on_delete: :cascade
    add_foreign_key :item_sets_users, :users, on_update: :cascade, on_delete: :cascade

  end

end
