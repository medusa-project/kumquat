class CreateMetadataProfiles < ActiveRecord::Migration
  def change
    create_table :metadata_profiles do |t|
      t.string :name
      t.integer :collection_id
      t.boolean :default

      t.timestamps null: false
    end
  end
end
