class AddRepositoryTitleToCollections < ActiveRecord::Migration
  def change
    add_column :collections, :repository_title, :string
  end
end
