class RenameBytestreamsToBinaries < ActiveRecord::Migration
  def change
    rename_column :bytestreams, :bytestream_type, :binary_type
    rename_table :bytestreams, :binaries
  end
end
