class AddDefaultValueToBytestreamMediaTypeColumn < ActiveRecord::Migration
  def change
    change_column_default :bytestreams, :media_type, 'unknown/unknown'
  end
end
