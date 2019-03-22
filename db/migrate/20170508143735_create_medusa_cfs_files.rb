class CreateMedusaCfsFiles < ActiveRecord::Migration[4.2]
  def change
    create_table :medusa_cfs_files do |t|
      t.string :uuid, null: false
      t.string :directory_uuid, null: false
      t.string :media_type
      t.string :repository_relative_pathname, null: false

      t.timestamps null: false
    end
    add_index :medusa_cfs_files, :uuid
  end
end
