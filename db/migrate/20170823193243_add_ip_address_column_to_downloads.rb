class AddIpAddressColumnToDownloads < ActiveRecord::Migration[4.2]
  def change
    add_column :downloads, :ip_address, :string
    add_index :downloads, :ip_address
  end
end
