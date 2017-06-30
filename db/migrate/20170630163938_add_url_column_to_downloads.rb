class AddUrlColumnToDownloads < ActiveRecord::Migration
  def change
    add_column :downloads, :url, :string
  end
end
