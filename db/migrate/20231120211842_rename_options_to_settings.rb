class RenameOptionsToSettings < ActiveRecord::Migration[7.1]
  def change
    rename_table :options, :settings
  end
end
