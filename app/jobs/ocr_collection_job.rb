##
# Runs OCR against all relevant {Binary binaries} in a collection.
#
# @see [OcrJob]
# @see [OcrItemJob]
#
class OcrCollectionJob < Job

  QUEUE = Job::Queue::ADMIN

  queue_as QUEUE

  ##
  # @param args [Array] One-element array containing a collection UUID.
  #
  def perform(*args)
    collection = Collection.find_by_repository_id(args[0])
    raise ActiveRecord::RecordNotFound unless collection

    self.task&.update(status_text: "Running OCR on #{collection.title}")

    Binary.uncached do
      # N.B.: these conditions must be kept in sync with Binary.ocrable?()
      binaries = Binary.joins(:item).
        where('items.collection_repository_id': collection.repository_id).
        where(full_text: nil).
        where(master_type: Binary::MasterType::ACCESS).
        where('media_type LIKE ? OR media_type = ?', 'image/%', 'application/pdf')
      binary_count = binaries.count
      binaries.each_with_index do |binary, index|
        binary.detect_text
        binary.save!
        self.task&.update(percent_complete: index / binary_count.to_f)
      end
    end
    self.task&.succeeded
  end

end
