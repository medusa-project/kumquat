class RemoveFolderNameColumnFromItems < ActiveRecord::Migration[5.1]
  def change
    # N.B.: @adolski has no idea where this column came from
    remove_column :items, :folder_name
  end
end
