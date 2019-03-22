class MakeAgentRelationsAgentRelationTypeColumnNotNull < ActiveRecord::Migration[4.2]
  def change
    change_column_null :agent_relations, :agent_relation_type_id, false
  end
end
