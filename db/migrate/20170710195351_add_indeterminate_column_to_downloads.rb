class AddIndeterminateColumnToDownloads < ActiveRecord::Migration[4.2]
  def change
    add_column :downloads, :indeterminate, :boolean, default: false
  end
end
