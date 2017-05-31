class AddIndexes2 < ActiveRecord::Migration
  def change
    add_index :binaries, :master_type
    add_index :binaries, :media_category
    add_index :binaries, :media_type

    add_index :collections, :harvestable

    add_index :elements, :name, unique: true

    add_index :entity_elements, :type
    add_index :entity_elements, :vocabulary_id
    add_index :entity_elements, :collection_id

    add_index :items, :variant

    add_index :metadata_profile_elements, :index
    add_index :metadata_profile_elements, :name
    add_index :metadata_profile_elements, :searchable
    add_index :metadata_profile_elements, :facetable
    add_index :metadata_profile_elements, :visible
    add_index :metadata_profile_elements, :sortable

    add_index :metadata_profiles, :name
    add_index :metadata_profiles, :default

    add_index :users, :username, unique: true

    add_index :vocabularies, :key, unique: true
  end
end
