class RenameItemSubclassColumnToVariant < ActiveRecord::Migration
  def change
    rename_column :items, :subclass, :variant
  end
end
