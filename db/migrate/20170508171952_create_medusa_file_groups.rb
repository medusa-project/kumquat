class CreateMedusaFileGroups < ActiveRecord::Migration
  def change
    create_table :medusa_file_groups do |t|
      t.string :uuid
      t.string :cfs_directory_uuid
      t.string :title

      t.timestamps null: false
    end
    add_index :medusa_file_groups, :uuid
  end
end
