class RenameItemNormalizedDateToDate < ActiveRecord::Migration[4.2]
  def change
    rename_column :items, :normalized_date, :date
  end
end
