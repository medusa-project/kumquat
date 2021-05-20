class AddTesseractJsonColumnToBinaries < ActiveRecord::Migration[6.1]
  def change
    add_column :binaries, :tesseract_json, :text
  end
end
