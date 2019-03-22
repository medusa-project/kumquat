class DropThemes < ActiveRecord::Migration[4.2]
  def change
    remove_column :collections, :theme_id
    drop_table :themes
  end
end
