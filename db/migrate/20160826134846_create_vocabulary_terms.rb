class CreateVocabularyTerms < ActiveRecord::Migration
  def change
    create_table :vocabulary_terms do |t|
      t.string :string
      t.string :uri
      t.integer :vocabulary_id
      t.timestamps null: false
    end
    add_index :vocabulary_terms, :string
    add_index :vocabulary_terms, :uri
    add_index :vocabulary_terms, :vocabulary_id
  end
end
