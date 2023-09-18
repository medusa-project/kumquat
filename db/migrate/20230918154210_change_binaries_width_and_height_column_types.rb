class ChangeBinariesWidthAndHeightColumnTypes < ActiveRecord::Migration[7.0]
  def change
    change_column :binaries, :width, :integer
    change_column :binaries, :height, :integer
  end
end
