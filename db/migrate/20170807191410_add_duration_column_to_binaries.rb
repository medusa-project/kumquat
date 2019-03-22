class AddDurationColumnToBinaries < ActiveRecord::Migration[4.2]
  def change
    add_column :binaries, :duration, :integer
  end
end
