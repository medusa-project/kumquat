class AddRepresentativeBinaryIdColumnToItems < ActiveRecord::Migration[4.2]
  def change
    add_column :items, :representative_binary_id, :integer
  end
end
