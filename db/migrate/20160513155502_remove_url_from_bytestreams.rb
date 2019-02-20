class RemoveUrlFromBytestreams < ActiveRecord::Migration[4.2]
  def change
    remove_column :bytestreams, :url
  end
end
