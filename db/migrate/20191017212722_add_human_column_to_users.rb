class AddHumanColumnToUsers < ActiveRecord::Migration[5.2]
  def change
    add_column :users, :human, :boolean, default: true, null: false
  end
end
