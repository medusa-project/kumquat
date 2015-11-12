class CreateFacetDefs < ActiveRecord::Migration
  def change
    create_table :facet_defs do |t|
      t.integer :index
      t.string :name
      t.string :solr_field

      t.timestamps null: false
    end
  end
end
