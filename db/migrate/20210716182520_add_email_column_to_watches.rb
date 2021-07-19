class AddEmailColumnToWatches < ActiveRecord::Migration[6.1]
  def change
    add_column :watches, :email, :string
    change_column_null :watches, :user_id, true
  end
end
