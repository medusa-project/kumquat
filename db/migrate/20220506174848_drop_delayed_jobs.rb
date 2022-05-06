class DropDelayedJobs < ActiveRecord::Migration[7.0]
  def change
    drop_table :delayed_jobs
  end
end
