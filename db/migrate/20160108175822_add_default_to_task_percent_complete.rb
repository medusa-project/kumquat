class AddDefaultToTaskPercentComplete < ActiveRecord::Migration[4.2]
  def change
    change_column :tasks, :percent_complete, :float, default: 0.0
  end
end
