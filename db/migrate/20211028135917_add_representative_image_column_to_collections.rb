class AddRepresentativeImageColumnToCollections < ActiveRecord::Migration[6.1]
  def change
    add_column :collections, :representative_image, :string
  end
end
