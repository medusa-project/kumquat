class AddCollectionJoins < ActiveRecord::Migration
  def change
    create_table :collection_joins do |t|
      t.string :parent_repository_id, null: false, index: true
      t.string :child_repository_id, null: false, index: true
    end
  end
end
