class RenameBytestreamTypeColumnToBytestreamType < ActiveRecord::Migration[4.2]
  def change
    rename_column :bytestreams, :type, :bytestream_type
  end
end
