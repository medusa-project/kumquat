class AddUriColumnToItemElements < ActiveRecord::Migration
  def change
    add_column :item_elements, :uri, :string
  end
end
