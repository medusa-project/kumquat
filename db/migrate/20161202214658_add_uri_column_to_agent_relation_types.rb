class AddUriColumnToAgentRelationTypes < ActiveRecord::Migration[4.2]
  def change
    add_column :agent_relation_types, :uri, :string
  end
end
