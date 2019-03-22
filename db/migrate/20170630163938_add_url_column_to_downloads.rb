class AddUrlColumnToDownloads < ActiveRecord::Migration[4.2]
  def change
    add_column :downloads, :url, :string
  end
end
