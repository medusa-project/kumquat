class RemoveItemsAllowedNetids < ActiveRecord::Migration[7.1]
  def change
    remove_column :items, :allowed_netids_deleteme
  end
end
