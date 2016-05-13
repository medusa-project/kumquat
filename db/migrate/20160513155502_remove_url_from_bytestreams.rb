class RemoveUrlFromBytestreams < ActiveRecord::Migration
  def change
    remove_column :bytestreams, :url
  end
end
