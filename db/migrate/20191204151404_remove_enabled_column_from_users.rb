class RemoveEnabledColumnFromUsers < ActiveRecord::Migration[6.0]
  def change
    remove_column :users, :enabled
  end
end
