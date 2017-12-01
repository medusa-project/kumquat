class AddContentdmIdentifiersToItems < ActiveRecord::Migration[4.2]
  def change
    add_column :items, :contentdm_alias, :string
    add_column :items, :contentdm_pointer, :integer
  end
end
