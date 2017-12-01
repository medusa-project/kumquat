class AddItemIdColumnToBytestreams < ActiveRecord::Migration[4.2]
  def change
    add_column :bytestreams, :item_id, :integer
  end
end
