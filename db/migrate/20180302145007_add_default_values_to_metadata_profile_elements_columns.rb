class AddDefaultValuesToMetadataProfileElementsColumns < ActiveRecord::Migration[5.1]
  def change
    change_column :metadata_profile_elements, :searchable, :boolean, default: true
    change_column :metadata_profile_elements, :sortable, :boolean, default: true
    change_column :metadata_profile_elements, :facetable, :boolean, default: true
    change_column :metadata_profile_elements, :visible, :boolean, default: true
  end
end
