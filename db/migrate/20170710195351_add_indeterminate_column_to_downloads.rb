class AddIndeterminateColumnToDownloads < ActiveRecord::Migration
  def change
    add_column :downloads, :indeterminate, :boolean, default: false
  end
end
