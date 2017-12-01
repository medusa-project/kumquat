class AddForeignKeyBetweenEntityElementsAndCollections < ActiveRecord::Migration[4.2]
  def change
    add_foreign_key :entity_elements, :collections,
                    on_update: :cascade, on_delete: :cascade
  end
end
