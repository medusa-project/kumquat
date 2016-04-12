class RenameItemNormalizedDateToDate < ActiveRecord::Migration
  def change
    rename_column :items, :normalized_date, :date
  end
end
