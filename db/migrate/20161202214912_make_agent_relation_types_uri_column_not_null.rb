class MakeAgentRelationTypesUriColumnNotNull < ActiveRecord::Migration[4.2]
  def change
    change_column_null :agent_relation_types, :uri, false
  end
end
