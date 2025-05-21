class AddOcredToItems < ActiveRecord::Migration[7.1]
  def change
    add_column :items, :ocred, :boolean, default: false
  end
end
