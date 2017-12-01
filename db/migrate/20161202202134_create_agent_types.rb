class CreateAgentTypes < ActiveRecord::Migration[4.2]
  def change
    create_table :agent_types do |t|
      t.string :name, null: false

      t.timestamps null: false
    end

    add_index :agent_types, :name, unique: true

    add_column :agents, :agent_type_id, :integer
    add_foreign_key :agents, :agent_types,
                    on_update: :cascade, on_delete: :restrict
  end
end
