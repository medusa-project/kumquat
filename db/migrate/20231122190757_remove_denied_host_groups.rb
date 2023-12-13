class RemoveDeniedHostGroups < ActiveRecord::Migration[7.1]
  def change
    remove_column :host_groups_items, :denied_host_group_id
    remove_column :host_groups_items, :effective_denied_host_group_id
    remove_column :collections_host_groups, :denied_host_group_id
  end
end
