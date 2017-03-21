class AddMediaCategoryColumnToBinaries < ActiveRecord::Migration
  def change
    add_column :binaries, :media_category, :integer
  end
end
