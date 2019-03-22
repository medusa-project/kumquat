class RenameItemSubclassColumnToVariant < ActiveRecord::Migration[4.2]
  def change
    rename_column :items, :subclass, :variant
  end
end
