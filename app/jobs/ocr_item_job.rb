##
# Runs OCR against the relevant binaries attached to an item and all of its
# child items.
#
# @see [OcrJob]
# @see [OcrCollectionJob]
#
class OcrItemJob < Job

  QUEUE = Job::Queue::ADMIN

  queue_as QUEUE

  ##
  # @param args [Array] One-element array containing an item UUID.
  #
  def perform(*args)
    main_item = Item.find_by_repository_id(args[0])
    raise ActiveRecord::RecordNotFound unless main_item

    Binary.uncached do
      items = [main_item] + main_item.all_children
      item_count = items.length
      self.task&.update(status_text: "Running OCR on #{main_item.title} and "\
          "#{item_count - 1} child items")
      items.each_with_index do |item, index|
        # N.B.: these conditions must be kept in sync with Binary.ocrable?()
        binaries = item.binaries.
          where(textract_json: nil).
          where(master_type: Binary::MasterType::ACCESS).
          where('media_type LIKE ? OR media_type = ?', 'image/%', 'application/pdf')
        binaries.each do |binary|
          binary.detect_text
          binary.save!
        end
        self.task&.update(percent_complete: index / item_count.to_f)
      end
    end
    self.task&.succeeded
  end

end
