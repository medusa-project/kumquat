class CreateItems < ActiveRecord::Migration
  def change
    create_table :items do |t|
      t.string :repository_id
      t.string :collection_repository_id
      t.string :parent_repository_id
      t.string :representative_item_repository_id
      t.string :subclass
      t.integer :page_number
      t.integer :subpage_number
      t.string :bib_id
      t.datetime :normalized_date
      t.boolean :published
      t.decimal :latitude, precision: 10, scale: 7
      t.decimal :longitude, precision: 10, scale: 7
      t.text :full_text
      t.datetime :last_indexed

      t.timestamps null: false
    end
  end
end
