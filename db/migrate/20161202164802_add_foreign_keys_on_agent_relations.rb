class AddForeignKeysOnAgentRelations < ActiveRecord::Migration[4.2]
  def change
    add_foreign_key :agent_relations, :agents, column: :agent_id,
                    on_update: :cascade, on_delete: :cascade
    add_foreign_key :agent_relations, :agents, column: :related_agent_id,
                    on_update: :cascade, on_delete: :cascade
  end
end
