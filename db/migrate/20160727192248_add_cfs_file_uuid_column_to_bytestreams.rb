class AddCfsFileUuidColumnToBytestreams < ActiveRecord::Migration[4.2]
  def change
    add_column :bytestreams, :cfs_file_uuid, :string
  end
end
