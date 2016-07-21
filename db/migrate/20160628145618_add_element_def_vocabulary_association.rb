class AddElementDefVocabularyAssociation < ActiveRecord::Migration
  def change
    create_join_table :element_defs, :vocabularies
  end
end
