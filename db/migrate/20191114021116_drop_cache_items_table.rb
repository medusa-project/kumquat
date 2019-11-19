class DropCacheItemsTable < ActiveRecord::Migration[6.0]
  def change
    drop_table :cache_items
  end
end
