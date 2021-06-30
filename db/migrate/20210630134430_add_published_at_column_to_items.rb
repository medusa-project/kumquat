class AddPublishedAtColumnToItems < ActiveRecord::Migration[6.1]
  def change
    add_column :items, :published_at, :datetime, null: true
    add_index :items, :published_at
  end
end
