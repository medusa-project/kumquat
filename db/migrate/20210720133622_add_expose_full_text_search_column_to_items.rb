class AddExposeFullTextSearchColumnToItems < ActiveRecord::Migration[6.1]
  def change
    add_column :items, :expose_full_text_search, :boolean, default: true, null: false
  end
end
