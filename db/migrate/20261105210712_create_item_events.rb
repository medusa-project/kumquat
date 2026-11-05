class CreateItemEvents < ActiveRecord::Migration[7.2]
  def change
    create_table :item_events do |t|
      t.string :event_type, null: false 
      t.references :item, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.jsonb :changeset, null: false

      t.timestamps
    end
  end
end
