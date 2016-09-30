class AddByteSizeColumnToBytestreams < ActiveRecord::Migration
  def change
    add_column :bytestreams, :byte_size, :integer, limit: 8 # bigint
  end
end
