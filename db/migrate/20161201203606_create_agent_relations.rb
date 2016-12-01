class CreateAgentRelations < ActiveRecord::Migration
  def change
    create_table :agent_relations do |t|
      t.integer :agent_id, null: false
      t.integer :related_agent_id, null: false
      t.string :dates
      t.text :description

      t.timestamps null: false
    end

    add_index :agent_relations, :agent_id
    add_index :agent_relations, :related_agent_id
  end
end
