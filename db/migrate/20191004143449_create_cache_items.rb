class CreateCacheItems < ActiveRecord::Migration[5.2]
  def change
    create_table :cache_items do |t|
      t.string :key
      t.string :value

      t.timestamps
    end
    add_index :cache_items, :key, unique: true
  end
end
