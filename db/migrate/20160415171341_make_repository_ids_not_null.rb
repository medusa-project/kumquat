class MakeRepositoryIdsNotNull < ActiveRecord::Migration[4.2]
  def change
    change_column_null :collections, :repository_id, false
    change_column_null :items, :repository_id, false
  end
end
