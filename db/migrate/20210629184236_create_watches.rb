class CreateWatches < ActiveRecord::Migration[6.1]
  def change
    create_table :watches do |t|
      t.bigint :user_id, null: false
      t.bigint :collection_id, null: false

      t.timestamps
    end
    add_foreign_key :watches, :users, on_update: :cascade, on_delete: :cascade
    add_foreign_key :watches, :collections, on_update: :cascade, on_delete: :cascade
  end
end
