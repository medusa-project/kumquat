class AddEmbedTagColumnToItems < ActiveRecord::Migration
  def change
    add_column :items, :embed_tag, :string
  end
end
