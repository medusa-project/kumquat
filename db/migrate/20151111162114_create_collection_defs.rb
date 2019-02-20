class CreateCollectionDefs < ActiveRecord::Migration[4.2]
  def change
    create_table :collection_defs do |t|
      t.string :repository_id
      t.integer :theme_id

      t.timestamps null: false
    end
  end
end
