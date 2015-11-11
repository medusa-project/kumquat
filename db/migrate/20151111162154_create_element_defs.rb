class CreateElementDefs < ActiveRecord::Migration
  def change
    create_table :element_defs do |t|
      t.integer :collection_id
      t.integer :metadata_profile_id
      t.string :name
      t.string :label
      t.integer :index
      t.boolean :searchable
      t.boolean :facetable
      t.boolean :visible

      t.timestamps null: false
    end
  end
end
