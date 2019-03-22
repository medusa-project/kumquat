class RedesignBytestreamPathnames < ActiveRecord::Migration[4.2]
  def change
    remove_column :bytestreams, :file_group_relative_pathname
    add_column :bytestreams, :repository_relative_pathname, :string
  end
end
