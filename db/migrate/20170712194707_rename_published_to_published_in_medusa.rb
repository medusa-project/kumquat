class RenamePublishedToPublishedInMedusa < ActiveRecord::Migration[4.2]
  def change
    rename_column :collections, :published, :published_in_medusa
  end
end
