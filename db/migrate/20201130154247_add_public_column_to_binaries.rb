class AddPublicColumnToBinaries < ActiveRecord::Migration[6.0]
  def change
    add_column :binaries, :public, :boolean, null: false, default: true
  end
end
