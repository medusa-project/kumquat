class AddQueueColumnToTasks < ActiveRecord::Migration[5.1]
  def change
    add_column :tasks, :queue, :string
  end
end
