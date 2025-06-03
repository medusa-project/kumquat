class BackfillOcredOnItems < ActiveRecord::Migration[7.1]
  def up
    Item.find_each do |item|
      if item.ocred_binaries.exists?
        item.update_column(:ocred, true)
      end
    end
  end
end
