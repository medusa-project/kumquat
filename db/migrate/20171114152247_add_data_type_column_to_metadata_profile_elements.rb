class AddDataTypeColumnToMetadataProfileElements < ActiveRecord::Migration[5.1]
  def change
    add_column :metadata_profile_elements, :data_type, :integer, null: false, default: 0
  end
end
