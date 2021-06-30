class AddCompoundUniqueIndexOnWatches < ActiveRecord::Migration[6.1]
  def change
    add_index :watches, [:user_id, :collection_id], unique: true
  end
end
