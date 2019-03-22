class AddDefaultValueToBytestreamMediaTypeColumn < ActiveRecord::Migration[4.2]
  def change
    change_column_default :bytestreams, :media_type, 'unknown/unknown'
  end
end
