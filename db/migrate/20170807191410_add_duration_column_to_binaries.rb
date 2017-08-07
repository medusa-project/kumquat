class AddDurationColumnToBinaries < ActiveRecord::Migration
  def change
    add_column :binaries, :duration, :integer
  end
end
