class DropThemes < ActiveRecord::Migration
  def change
    remove_column :collections, :theme_id
    drop_table :themes
  end
end
