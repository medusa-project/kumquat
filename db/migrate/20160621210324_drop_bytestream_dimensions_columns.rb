class DropBytestreamDimensionsColumns < ActiveRecord::Migration
  def change
    remove_column :bytestreams, :width
    remove_column :bytestreams, :height
  end
end
