class AddContentdmAliasColumnToCollections < ActiveRecord::Migration[4.2]
  def change
    add_column :collections, :contentdm_alias, :string
  end
end
