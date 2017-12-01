class CreateBytestreams < ActiveRecord::Migration[4.2]
  def change
    create_table :bytestreams do |t|
      t.integer :type
      t.string :media_type
      t.string :file_group_relative_pathname
      t.string :url
      t.integer :width
      t.integer :height

      t.timestamps null: false
    end
  end
end
