class AddByteSizeColumnToBytestreams < ActiveRecord::Migration[4.2]
  def change
    add_column :bytestreams, :byte_size, :integer, limit: 8 # bigint
  end
end
