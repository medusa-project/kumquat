class RenameBinariesRepositoryRelativePathnameToObjectKey < ActiveRecord::Migration[5.1]
  def change
    rename_column :binaries, :repository_relative_pathname, :object_key
    # trim leading slashes
    execute "UPDATE binaries SET object_key = substr(object_key, 2);"
  end
end
