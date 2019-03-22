class AddElementDefVocabularyAssociation < ActiveRecord::Migration[4.2]
  def change
    create_join_table :element_defs, :vocabularies
  end
end
