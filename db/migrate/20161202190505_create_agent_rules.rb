class CreateAgentRules < ActiveRecord::Migration
  def change
    create_table :agent_rules do |t|
      t.string :name, null: false
      t.string :abbreviation

      t.timestamps null: false
    end

    add_index :agent_rules, :name, unique: true
    add_index :agent_rules, :abbreviation, unique: true

    add_column :agents, :agent_rule_id, :integer
    add_foreign_key :agents, :agent_rules,
                    on_update: :cascade, on_delete: :restrict
  end
end
