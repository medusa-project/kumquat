class AddContentdmAliasColumnToCollections < ActiveRecord::Migration
  def change
    add_column :collections, :contentdm_alias, :string
  end
end
