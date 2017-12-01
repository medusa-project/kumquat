class RenameElementDefsToMetadataProfileElements < ActiveRecord::Migration[4.2]
  def change
    rename_column :element_defs_vocabularies, :element_def_id,
                  :metadata_profile_element_id
    rename_column :metadata_profiles, :default_sortable_element_def_id,
                  :default_sortable_element_id

    rename_table :element_defs, :metadata_profile_elements
    rename_table :element_defs_vocabularies, :metadata_profile_elements_vocabularies
  end
end
