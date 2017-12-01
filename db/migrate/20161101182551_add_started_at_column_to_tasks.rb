class AddStartedAtColumnToTasks < ActiveRecord::Migration[4.2]
  def change
    add_column :tasks, :started_at, :datetime
  end
end
