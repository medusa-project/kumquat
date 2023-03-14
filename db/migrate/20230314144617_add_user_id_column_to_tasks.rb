class AddUserIdColumnToTasks < ActiveRecord::Migration[7.0]
  def change
    add_column :tasks, :user_id, :bigint
    add_index :tasks, :user_id
    add_foreign_key :tasks, :users, on_update: :cascade, on_delete: :nullify
  end
end
