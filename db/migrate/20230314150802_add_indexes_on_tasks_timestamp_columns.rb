class AddIndexesOnTasksTimestampColumns < ActiveRecord::Migration[7.0]
  def change
    add_index :tasks, :created_at
    add_index :tasks, :updated_at
    add_index :tasks, :started_at
    add_index :tasks, :stopped_at
  end
end
