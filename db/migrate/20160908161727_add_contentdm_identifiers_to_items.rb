class AddContentdmIdentifiersToItems < ActiveRecord::Migration
  def change
    add_column :items, :contentdm_alias, :string
    add_column :items, :contentdm_pointer, :integer
  end
end
