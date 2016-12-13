class AddUniqueIndexOnAgentRelations < ActiveRecord::Migration
  def change
    add_index :agent_relations,
              [:agent_id, :agent_relation_type_id, :related_agent_id],
              unique: true,
              name: 'by_relationship'
  end
end
