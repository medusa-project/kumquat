class AddMediaCategoryColumnToBinaries < ActiveRecord::Migration[4.2]
  def change
    add_column :binaries, :media_category, :integer
  end
end
