class AddItemIdColumnToElements < ActiveRecord::Migration[4.2]
  def change
    add_column :elements, :item_id, :integer
  end
end
