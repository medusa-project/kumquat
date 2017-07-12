class RenamePublishedToPublishedInMedusa < ActiveRecord::Migration
  def change
    rename_column :collections, :published, :published_in_medusa
  end
end
