class DropTitleAndDescriptionColumnsOnCollections < ActiveRecord::Migration[4.2]
  def change
    remove_column :collections, :title
    remove_column :collections, :description
  end
end
