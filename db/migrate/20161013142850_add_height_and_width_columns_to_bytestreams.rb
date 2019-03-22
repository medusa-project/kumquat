class AddHeightAndWidthColumnsToBytestreams < ActiveRecord::Migration[4.2]
  def change
    add_column :bytestreams, :width, :decimal, precision: 6, scale: 0
    add_column :bytestreams, :height, :decimal, precision: 6, scale: 0
  end
end
