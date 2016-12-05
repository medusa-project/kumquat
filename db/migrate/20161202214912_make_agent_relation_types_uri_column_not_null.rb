class MakeAgentRelationTypesUriColumnNotNull < ActiveRecord::Migration
  def change
    change_column_null :agent_relation_types, :uri, false
  end
end
