class RenameCollectionsPublishedInMedusaToPublicInMedusa < ActiveRecord::Migration[4.2]
  def change
    rename_column :collections, :published_in_medusa, :public_in_medusa
  end
end
