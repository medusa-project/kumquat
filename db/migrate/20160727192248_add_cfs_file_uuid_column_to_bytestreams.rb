class AddCfsFileUuidColumnToBytestreams < ActiveRecord::Migration
  def change
    add_column :bytestreams, :cfs_file_uuid, :string
  end
end
