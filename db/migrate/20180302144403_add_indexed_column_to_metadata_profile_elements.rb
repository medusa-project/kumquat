class AddIndexedColumnToMetadataProfileElements < ActiveRecord::Migration[5.1]
  def change
    add_column :metadata_profile_elements, :indexed, :boolean, default: true

    add_index :metadata_profile_elements, :indexed

    execute 'UPDATE metadata_profile_elements SET indexed = searchable'
  end
end
