class RenameBytestreamsToBinaries < ActiveRecord::Migration[4.2]
  def change
    rename_column :bytestreams, :bytestream_type, :binary_type
    rename_table :bytestreams, :binaries
  end
end
