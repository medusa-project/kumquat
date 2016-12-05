class RemoveLastAndVariantNamesFromAgents < ActiveRecord::Migration
  def change
    remove_column :agents, :last_name
    remove_column :agents, :variant_name
  end
end
