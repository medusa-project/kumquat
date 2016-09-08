class AddBacktraceColumnToTasks < ActiveRecord::Migration
  def change
    add_column :tasks, :backtrace, :text
  end
end
