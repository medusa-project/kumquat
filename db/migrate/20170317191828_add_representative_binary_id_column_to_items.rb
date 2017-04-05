class AddRepresentativeBinaryIdColumnToItems < ActiveRecord::Migration
  def change
    add_column :items, :representative_binary_id, :integer
  end
end
