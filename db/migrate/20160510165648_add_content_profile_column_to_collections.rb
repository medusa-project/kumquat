class AddContentProfileColumnToCollections < ActiveRecord::Migration
  def change
    add_column :collections, :content_profile_id, :integer
  end
end
