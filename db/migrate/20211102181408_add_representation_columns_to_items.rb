class AddRepresentationColumnsToItems < ActiveRecord::Migration[6.1]
  def change
    add_column :items, :representative_image, :string
    add_column :items, :representation_type, :string
    rename_column :items, :representative_binary_id, :representative_medusa_file_id
    change_column :items, :representative_medusa_file_id, :string

    execute "UPDATE items SET representation_type = 'item' WHERE representative_item_id IS NOT NULL;"
    execute "UPDATE items SET representation_type = 'medusa_file' WHERE representative_medusa_file_id IS NOT NULL;"
  end
end
