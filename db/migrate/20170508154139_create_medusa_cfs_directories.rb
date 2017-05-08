class CreateMedusaCfsDirectories < ActiveRecord::Migration
  def change
    create_table :medusa_cfs_directories do |t|
      t.string :uuid, null: false
      t.string :parent_uuid
      t.string :repository_relative_pathname, null: false
      t.integer :medusa_database_id

      t.timestamps null: false
    end
    add_index :medusa_cfs_directories, :uuid
  end
end
