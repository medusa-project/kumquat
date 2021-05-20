class RemoveBinariesTextractJsonColumn < ActiveRecord::Migration[6.1]
  def change
    remove_column :binaries, :textract_json
  end
end
