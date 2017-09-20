class AddUniqueIndexOnBinariesRepositoryRelativePathname < ActiveRecord::Migration[4.2]
  def change
    add_index :binaries, :repository_relative_pathname, unique: true
  end
end
