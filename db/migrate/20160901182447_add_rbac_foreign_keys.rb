class AddRbacForeignKeys < ActiveRecord::Migration
  def change
    remove_index :roles_users, :role_id
    remove_index :roles_users, :user_id
    add_foreign_key :roles_users, :roles, on_delete: :cascade, on_update: :cascade
    add_foreign_key :roles_users, :users, on_delete: :cascade, on_update: :cascade

    remove_index :permissions_roles, :permission_id
    remove_index :permissions_roles, :role_id
    add_foreign_key :permissions_roles, :permissions, on_delete: :cascade, on_update: :cascade
    add_foreign_key :permissions_roles, :roles, on_delete: :cascade, on_update: :cascade
  end
end
