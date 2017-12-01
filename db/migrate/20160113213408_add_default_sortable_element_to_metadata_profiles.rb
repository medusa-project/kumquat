class AddDefaultSortableElementToMetadataProfiles < ActiveRecord::Migration[4.2]
  def change
    add_column :metadata_profiles, :default_sortable_element_def_id, :integer
    remove_column :element_defs, :is_default_sort
  end
end
