class CreateDownloads < ActiveRecord::Migration[4.2]
  def change
    create_table :downloads do |t|
      t.string :key, null: false
      t.integer :status, null: false, default: 0
      t.string :filename
      t.float :percent_complete, default: 0.0

      t.timestamps null: false
    end
  end
end
