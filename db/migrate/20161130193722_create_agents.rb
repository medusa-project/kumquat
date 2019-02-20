class CreateAgents < ActiveRecord::Migration[4.2]
  def change
    create_table :agents do |t|
      t.string :uri, null: false
      t.string :name, null: false
      t.string :last_name
      t.string :variant_name
      t.datetime :begin_date
      t.datetime :end_date
      t.text :description

      t.timestamps null: false
    end

    add_index :agents, :uri, unique: true
    add_index :agents, :name
    add_index :agents, :last_name
    add_index :agents, :variant_name
    add_index :agents, :begin_date
    add_index :agents, :end_date
  end
end
