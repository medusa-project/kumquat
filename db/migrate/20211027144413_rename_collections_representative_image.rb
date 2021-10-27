class RenameCollectionsRepresentativeImage < ActiveRecord::Migration[6.1]
  def change
    rename_column :collections, :representative_image, :representative_medusa_file_id
  end
end
