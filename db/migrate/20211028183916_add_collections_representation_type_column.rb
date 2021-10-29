class AddCollectionsRepresentationTypeColumn < ActiveRecord::Migration[6.1]
  def change
    add_column :collections, :representation_type, :string
    execute "UPDATE collections SET representation_type = 'item' WHERE representative_item_id IS NOT NULL;"
    execute "UPDATE collections SET representation_type = 'medusa_file' WHERE representative_medusa_file_id IS NOT NULL;"
  end
end
