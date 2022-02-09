class AddIndexesOnForeignKeyColumns < ActiveRecord::Migration[6.1]
  def change
    add_index :agent_uris, :agent_id
    add_index :agents, :agent_rule_id
    add_index :agents, :agent_type_id
    add_index :collections, :descriptive_element_id
    add_index :collections_host_groups, :collection_id
    add_index :collections_host_groups, :allowed_host_group_id
    add_index :collections_host_groups, :denied_host_group_id
    add_index :downloads, :task_id
    add_index :host_groups_items, :item_id
    add_index :host_groups_items, :allowed_host_group_id
    add_index :host_groups_items, :denied_host_group_id
    add_index :host_groups_items, :effective_allowed_host_group_id
    add_index :host_groups_items, :effective_denied_host_group_id
    add_index :item_sets, :collection_repository_id
  end
end
