class RemoveLastAndVariantNamesFromAgents < ActiveRecord::Migration[4.2]
  def change
    remove_column :agents, :last_name
    remove_column :agents, :variant_name
  end
end
