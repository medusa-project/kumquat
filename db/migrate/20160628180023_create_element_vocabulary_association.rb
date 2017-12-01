class CreateElementVocabularyAssociation < ActiveRecord::Migration[4.2]
  def change
    add_column :elements, :vocabulary_id, :integer
  end
end
