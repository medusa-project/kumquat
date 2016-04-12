class RenameBytestreamTypeColumnToBytestreamType < ActiveRecord::Migration
  def change
    rename_column :bytestreams, :type, :bytestream_type
  end
end
