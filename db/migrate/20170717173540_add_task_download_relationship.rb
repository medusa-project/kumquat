class AddTaskDownloadRelationship < ActiveRecord::Migration
  def up
    add_column :downloads, :task_id, :integer
    #add_foreign_key :downloads, :tasks, on_update: :cascade, on_delete: :restrict

    remove_column :downloads, :percent_complete
    remove_column :downloads, :indeterminate
    remove_column :downloads, :status
  end

  def down
    remove_foreign_key :downloads, column: :task_id
    remove_column :downloads, :task_id
    add_column :downloads, :percent_complete, :float
    add_column :downloads, :indeterminate, :boolean
    add_column :downloads, :status, :integer
  end
end
