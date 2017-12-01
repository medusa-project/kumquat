class CreatePermissions < ActiveRecord::Migration[4.2]
  def change
    create_table :permissions do |t|
      t.string :key

      t.timestamps null: false
    end
  end
end
