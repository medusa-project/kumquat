class AddUniqueIndexOnAgentNames < ActiveRecord::Migration[4.2]
  def change
    remove_index :agents, :name
    add_index :agents, :name, unique: true
  end
end
