class CreateHosts < ActiveRecord::Migration[4.2]
  def change
    create_table :hosts do |t|
      t.string :pattern
      t.integer :role_id
      t.timestamps null: false
    end

    add_foreign_key :hosts, :roles, on_delete: :cascade, on_update: :cascade

    create_table :collections_roles do |t|
      t.integer :collection_id
      t.integer :allowed_role_id
      t.integer :denied_role_id
    end

    add_foreign_key :collections_roles, :collections,
                    on_delete: :cascade, on_update: :cascade
    add_foreign_key :collections_roles, :roles, column: :allowed_role_id,
                    on_delete: :cascade, on_update: :cascade
    add_foreign_key :collections_roles, :roles, column: :denied_role_id,
                    on_delete: :cascade, on_update: :cascade

    create_table :items_roles do |t|
      t.integer :item_id
      t.integer :allowed_role_id
      t.integer :denied_role_id
    end

    add_foreign_key :items_roles, :items,
                    on_delete: :cascade, on_update: :cascade
    add_foreign_key :items_roles, :roles, column: :allowed_role_id,
                    on_delete: :cascade, on_update: :cascade
    add_foreign_key :items_roles, :roles, column: :denied_role_id,
                    on_delete: :cascade, on_update: :cascade
  end
end
