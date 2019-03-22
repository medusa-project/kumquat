class AddEmbedTagColumnToItems < ActiveRecord::Migration[4.2]
  def change
    add_column :items, :embed_tag, :string
  end
end
