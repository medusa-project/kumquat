class AddContentProfileColumnToCollections < ActiveRecord::Migration[4.2]
  def change
    add_column :collections, :content_profile_id, :integer
  end
end
