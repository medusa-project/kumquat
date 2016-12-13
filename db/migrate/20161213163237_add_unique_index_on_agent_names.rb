class AddUniqueIndexOnAgentNames < ActiveRecord::Migration
  def change
    remove_index :agents, :name
    add_index :agents, :name, unique: true
  end
end
