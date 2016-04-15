class MakeItemsPublishedByDefault < ActiveRecord::Migration
  def change
    change_column_default :items, :published, true
  end
end
