class RemoveItemBibIdColumn < ActiveRecord::Migration
  def change
    remove_column :items, :bib_id
  end
end
