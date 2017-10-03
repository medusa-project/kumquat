class AddIndexOnCollectionsRepositoryId < ActiveRecord::Migration[5.1]
  def change
    add_index :collections, :repository_id, unique: true
  end
end
