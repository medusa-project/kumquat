class AddUriColumnToAgentRelationTypes < ActiveRecord::Migration
  def change
    add_column :agent_relation_types, :uri, :string
  end
end
