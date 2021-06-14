class AddOcredAtColumnToBinaries < ActiveRecord::Migration[6.1]
  def change
    add_column :binaries, :ocred_at, :datetime, null: true
    add_index :binaries, :ocred_at
  end
end
