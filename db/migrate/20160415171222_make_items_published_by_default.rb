class MakeItemsPublishedByDefault < ActiveRecord::Migration[4.2]
  def change
    change_column_default :items, :published, true
  end
end
