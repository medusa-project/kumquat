class AddExpiredColumnToDownloads < ActiveRecord::Migration[4.2]
  def change
    add_column :downloads, :expired, :boolean, default: false
    add_index :downloads, :expired
  end
end
