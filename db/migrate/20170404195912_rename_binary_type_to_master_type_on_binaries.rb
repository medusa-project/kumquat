class RenameBinaryTypeToMasterTypeOnBinaries < ActiveRecord::Migration
  def change
    rename_column :binaries, :binary_type, :master_type
  end
end
