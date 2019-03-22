class CreateRoles < ActiveRecord::Migration[4.2]
  def change
    create_table :roles do |t|
      t.string :key
      t.string :name
      t.boolean :required

      t.timestamps null: false
    end
    create_table :permissions_roles do |t|
      t.integer :permission_id
      t.integer :role_id
    end
    create_table :roles_users do |t|
      t.integer :user_id
      t.integer :role_id
    end
  end
end
