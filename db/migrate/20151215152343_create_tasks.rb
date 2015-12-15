class CreateTasks < ActiveRecord::Migration
  def change
    create_table :tasks do |t|
      t.string :name
      t.decimal :status
      t.string :status_text
      t.string :job_id
      t.float :percent_complete
      t.datetime :completed_at

      t.timestamps null: false
    end
  end
end
