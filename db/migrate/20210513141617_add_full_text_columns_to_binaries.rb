class AddFullTextColumnsToBinaries < ActiveRecord::Migration[6.1]
  def change
    add_column :binaries, :full_text, :text
    add_column :binaries, :hocr, :text
  end
end
