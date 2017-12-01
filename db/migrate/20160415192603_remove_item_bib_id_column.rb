class RemoveItemBibIdColumn < ActiveRecord::Migration[4.2]
  def change
    remove_column :items, :bib_id
  end
end
