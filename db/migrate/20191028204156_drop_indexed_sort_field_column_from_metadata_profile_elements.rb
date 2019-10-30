class DropIndexedSortFieldColumnFromMetadataProfileElements < ActiveRecord::Migration[5.2]
  def change
    if column_exists? :metadata_profile_elements, :indexed_sort_field
      remove_column :metadata_profile_elements, :indexed_sort_field
    end
  end
end
