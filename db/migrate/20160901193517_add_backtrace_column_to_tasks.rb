class AddBacktraceColumnToTasks < ActiveRecord::Migration[4.2]
  def change
    add_column :tasks, :backtrace, :text
  end
end
