class RenameItemsRepresentativeItemRepositoryId < ActiveRecord::Migration[6.1]
  def change
    rename_column :items, :representative_item_repository_id, :representative_item_id
  end
end
