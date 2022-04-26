class AddUniqueIndexOnTasksJobId < ActiveRecord::Migration[7.0]
  def change
    execute "DELETE FROM tasks WHERE LENGTH(job_id) < 8;"
    add_index :tasks, :job_id, unique: true
  end
end
