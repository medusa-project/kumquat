class MakeAgentRelationsAgentRelationTypeColumnNotNull < ActiveRecord::Migration
  def change
    change_column_null :agent_relations, :agent_relation_type_id, false
  end
end
