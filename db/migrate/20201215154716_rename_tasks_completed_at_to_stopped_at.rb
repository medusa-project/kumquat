class RenameTasksCompletedAtToStoppedAt < ActiveRecord::Migration[6.1]
  def change
    rename_column :tasks, :completed_at, :stopped_at
  end
end
