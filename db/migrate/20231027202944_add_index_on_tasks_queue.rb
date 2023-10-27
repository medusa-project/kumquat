class AddIndexOnTasksQueue < ActiveRecord::Migration[7.0]
  def change
    add_index :tasks, :queue
  end
end
