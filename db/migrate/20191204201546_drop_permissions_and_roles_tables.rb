class DropPermissionsAndRolesTables < ActiveRecord::Migration[6.0]
  def change
    drop_table :permissions_roles
    drop_table :permissions
    drop_table :roles_users
    drop_table :roles
  end
end
