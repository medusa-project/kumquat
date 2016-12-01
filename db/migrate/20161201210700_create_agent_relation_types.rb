class CreateAgentRelationTypes < ActiveRecord::Migration
  def change
    create_table :agent_relation_types do |t|
      t.string :name, null: false
      t.text :description

      t.timestamps null: false
    end

    add_column :agent_relations, :agent_relation_type_id, :integer

    add_foreign_key :agent_relations, :agent_relation_types,
                    on_update: :cascade, on_delete: :restrict
  end
end
