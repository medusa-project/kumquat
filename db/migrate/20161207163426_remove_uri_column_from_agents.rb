class RemoveUriColumnFromAgents < ActiveRecord::Migration[4.2]
  def change
    remove_column :agents, :uri
  end
end
