class RemoveUriColumnFromAgents < ActiveRecord::Migration
  def change
    remove_column :agents, :uri
  end
end
