class AddIndexes < ActiveRecord::Migration[4.2]
  def change
    add_index :bytestreams, :item_id
    add_index :collections, :repository_id, unique: true
    add_index :collections, :published
    add_index :collections, :published_in_dls
    add_index :collections, :representative_item_id
    add_index :collections, :theme_id
    add_index :collections, :metadata_profile_id
    add_index :element_defs, :collection_id
    add_index :element_defs, :metadata_profile_id
    add_index :elements, :item_id
    add_index :items, :repository_id, unique: true
    add_index :items, :collection_repository_id
    add_index :items, :parent_repository_id
    add_index :items, :representative_item_repository_id
    add_index :metadata_profiles, :default_sortable_element_def_id
    add_index :options, :key, unique: true
    add_index :permissions_roles, :permission_id
    add_index :permissions_roles, :role_id
    add_index :roles, :key
    add_index :roles_users, :user_id
    add_index :roles_users, :role_id
  end
end
