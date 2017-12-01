class AddDetailColumnToTasks < ActiveRecord::Migration[4.2]
  def change
    add_column :tasks, :detail, :text
  end
end
