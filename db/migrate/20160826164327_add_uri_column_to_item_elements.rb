class AddUriColumnToItemElements < ActiveRecord::Migration[4.2]
  def change
    add_column :item_elements, :uri, :string
  end
end
