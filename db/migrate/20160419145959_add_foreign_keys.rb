class AddForeignKeys < ActiveRecord::Migration[4.2]
  def change
    add_foreign_key :bytestreams, :items, on_delete: :cascade
    add_foreign_key :elements, :items, on_delete: :cascade
    add_foreign_key :element_defs, :metadata_profiles, on_delete: :cascade
  end
end
