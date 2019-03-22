class CreateMedusaRepositories < ActiveRecord::Migration[4.2]
  def change
    create_table :medusa_repositories do |t|
      t.integer :medusa_database_id
      t.string :contact_email
      t.string :email
      t.string :title

      t.timestamps null: false
    end
    add_index :medusa_repositories, :medusa_database_id
  end
end
