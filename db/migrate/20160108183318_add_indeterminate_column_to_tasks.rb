class AddIndeterminateColumnToTasks < ActiveRecord::Migration
  def change
    add_column :tasks, :indeterminate, :boolean, default: false
  end
end
