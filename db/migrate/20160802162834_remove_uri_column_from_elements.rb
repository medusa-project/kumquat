class RemoveUriColumnFromElements < ActiveRecord::Migration
  def change
    remove_column :elements, :uri
  end
end
