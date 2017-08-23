class AddExpiredColumnToDownloads < ActiveRecord::Migration
  def change
    add_column :downloads, :expired, :boolean, default: false
    add_index :downloads, :expired
  end
end
