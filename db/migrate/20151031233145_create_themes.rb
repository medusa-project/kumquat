class CreateThemes < ActiveRecord::Migration
  def change
    create_table :themes do |t|
      t.string :name
      t.boolean :required, default: false
      t.boolean :default, default: false

      t.timestamps null: false
    end
  end
end
