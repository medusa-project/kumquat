class DropIndexedSortFieldColumnFromMetadataProfileElements < ActiveRecord::Migration[5.2]
  def change
    remove_column :metadata_profile_elements, :indexed_sort_field
  end
end
