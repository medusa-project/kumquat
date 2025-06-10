class BackfillOcredOnItemsAgain < ActiveRecord::Migration[7.1]
  def up
    # This migration is a workaround for the fact that some items were not
    # marked as ocred when they should have been, due to a bug in the OCR jobs.
    Item.find_each do |item|
      if item.ocred_binaries(recursive: true).exists?
        item.update_column(:ocred, true)
      end
    end
  end
end
