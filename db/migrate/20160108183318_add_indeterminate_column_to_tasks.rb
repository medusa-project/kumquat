class AddIndeterminateColumnToTasks < ActiveRecord::Migration[4.2]
  def change
    add_column :tasks, :indeterminate, :boolean, default: false
  end
end
