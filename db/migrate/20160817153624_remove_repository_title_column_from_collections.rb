class RemoveRepositoryTitleColumnFromCollections < ActiveRecord::Migration[4.2]
  def change
    remove_column :collections, :repository_title
  end
end
