class RenameBinaryTypeToMasterTypeOnBinaries < ActiveRecord::Migration[4.2]
  def change
    rename_column :binaries, :binary_type, :master_type
  end
end
