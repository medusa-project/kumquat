class CreateElementVocabularyAssociation < ActiveRecord::Migration
  def change
    add_column :elements, :vocabulary_id, :integer
  end
end
