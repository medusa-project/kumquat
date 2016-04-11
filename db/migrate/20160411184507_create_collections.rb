class CreateCollections < ActiveRecord::Migration
  def change
    create_table :collections do |t|
      t.string :repository_id
      t.string :title
      t.string :description
      t.string :description_html
      t.string :access_url
      t.boolean :published
      t.boolean :published_in_dls
      t.string :representative_image
      t.string :representative_item_id
      t.integer :theme_id
      t.integer :metadata_profile_id
      t.integer :medusa_data_file_group_id
      t.integer :medusa_metadata_file_group_id

      t.timestamps null: false
    end
  end
end
