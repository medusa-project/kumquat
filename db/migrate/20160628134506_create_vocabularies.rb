class CreateVocabularies < ActiveRecord::Migration[4.2]
  def change
    create_table :vocabularies do |t|
      t.string :key
      t.string :name

      t.timestamps null: false
    end
  end
end
