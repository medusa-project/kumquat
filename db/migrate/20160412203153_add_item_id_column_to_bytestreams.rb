class AddItemIdColumnToBytestreams < ActiveRecord::Migration
  def change
    add_column :bytestreams, :item_id, :integer
  end
end
