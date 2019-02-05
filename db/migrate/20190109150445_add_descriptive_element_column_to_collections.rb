class AddDescriptiveElementColumnToCollections < ActiveRecord::Migration[5.1]
  def change
    add_column :collections, :descriptive_element_id, :integer
    add_foreign_key :collections, :metadata_profile_elements,
                    column: :descriptive_element_id,
                    on_update: :cascade, on_delete: :nullify
  end
end
