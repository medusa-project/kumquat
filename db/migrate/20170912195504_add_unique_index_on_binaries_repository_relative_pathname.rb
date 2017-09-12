class AddUniqueIndexOnBinariesRepositoryRelativePathname < ActiveRecord::Migration
  def change
    add_index :binaries, :repository_relative_pathname, unique: true
  end
end
