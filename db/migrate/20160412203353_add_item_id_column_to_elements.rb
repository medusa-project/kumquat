class AddItemIdColumnToElements < ActiveRecord::Migration
  def change
    add_column :elements, :item_id, :integer
  end
end
