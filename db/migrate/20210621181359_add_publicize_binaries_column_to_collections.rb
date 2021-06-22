class AddPublicizeBinariesColumnToCollections < ActiveRecord::Migration[6.1]
  def change
    add_column :collections, :publicize_binaries, :boolean, default: true, null: false
  end
end
