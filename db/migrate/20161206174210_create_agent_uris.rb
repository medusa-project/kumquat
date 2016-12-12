class CreateAgentUris < ActiveRecord::Migration
  def change
    create_table :agent_uris do |t|
      t.string :uri, null: false
      t.integer :agent_id
      t.boolean :primary, default: false

      t.timestamps null: false
    end
    add_index :agent_uris, :uri, unique: true
    add_foreign_key :agent_uris, :agents,
                    on_update: :cascade, on_delete: :cascade
  end
end
