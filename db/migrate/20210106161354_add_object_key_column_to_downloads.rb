class AddObjectKeyColumnToDownloads < ActiveRecord::Migration[6.1]
  def change
    # This is needed in CI (I don't know why)
    add_column :downloads, :object_key, :string unless column_exists?(:downloads, :object_key)
  end
end
