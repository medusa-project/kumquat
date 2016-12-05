class AddForeignKeyBetweenEntityElementsAndCollections < ActiveRecord::Migration
  def change
    add_foreign_key :entity_elements, :collections,
                    on_update: :cascade, on_delete: :cascade
  end
end
