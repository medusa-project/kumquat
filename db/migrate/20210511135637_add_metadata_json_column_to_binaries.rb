class AddMetadataJsonColumnToBinaries < ActiveRecord::Migration[6.1]
  def change
    add_column :binaries, :metadata_json, :text
  end
end
