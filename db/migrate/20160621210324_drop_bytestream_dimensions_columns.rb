class DropBytestreamDimensionsColumns < ActiveRecord::Migration[4.2]
  def change
    remove_column :bytestreams, :width
    remove_column :bytestreams, :height
  end
end
