class AddVocabularyForeignKeys < ActiveRecord::Migration[4.2]
  def change
    add_foreign_key :item_elements, :vocabularies, on_delete: :restrict
    add_foreign_key :vocabulary_terms, :vocabularies, on_delete: :cascade
  end
end
