class AddMetadataProfileForeignKeys < ActiveRecord::Migration
  def change
    #add_foreign_key :metadata_profile_elements, :metadata_profiles,
    #                on_delete: :cascade, on_update: :cascade
    add_foreign_key :metadata_profiles, :metadata_profile_elements,
                    column: :default_sortable_element_id,
                    on_delete: :nullify, on_update: :cascade

    add_foreign_key :metadata_profile_elements_vocabularies,
                    :metadata_profile_elements,
                    on_delete: :cascade, on_update: :cascade
    add_foreign_key :metadata_profile_elements_vocabularies, :vocabularies,
                    on_delete: :cascade, on_update: :cascade
  end
end
