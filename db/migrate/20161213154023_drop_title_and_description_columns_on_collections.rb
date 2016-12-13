class DropTitleAndDescriptionColumnsOnCollections < ActiveRecord::Migration
  def change
    remove_column :collections, :title
    remove_column :collections, :description
  end
end
