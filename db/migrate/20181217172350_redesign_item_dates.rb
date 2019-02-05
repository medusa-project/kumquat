class RedesignItemDates < ActiveRecord::Migration[5.1]
  def change
    rename_column :items, :date, :start_date
    add_column :items, :end_date, :datetime
  end
end
