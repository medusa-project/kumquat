class CreateItemSets < ActiveRecord::Migration[4.2]
  def change
    create_table :item_sets do |t|
      t.string :name, null: false
      t.string :collection_repository_id, null: false

      t.timestamps null: false
    end

    create_table :item_sets_users do |t|
      t.integer :item_set_id
      t.integer :user_id
    end

    add_index :item_sets_users, :item_set_id
    add_index :item_sets_users, :user_id
  end
end
