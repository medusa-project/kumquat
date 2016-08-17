class RemoveRepositoryTitleColumnFromCollections < ActiveRecord::Migration
  def change
    remove_column :collections, :repository_title
  end
end
