class AddTextractJsonColumnToBinaries < ActiveRecord::Migration[6.1]
  def change
    add_column :binaries, :textract_json, :text
  end
end
