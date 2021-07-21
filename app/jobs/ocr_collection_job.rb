##
# Runs OCR against all relevant {Binary binaries} in a collection.
#
class OcrCollectionJob < Job

  LOGGER = CustomLogger.new(OcrCollectionJob)
  QUEUE  = Job::Queue::ADMIN

  queue_as QUEUE

  def self.num_threads
    OcrItemJob.num_threads
  end

  ##
  # @param args [Array] One-element array containing a collection UUID.
  #
  def perform(*args)
    collection = Collection.find_by_repository_id(args[0])
    raise ActiveRecord::RecordNotFound unless collection

    # N.B.: these conditions must be kept in sync with Binary.ocrable?()
    binaries     = Binary.joins(:item).
      where('items.collection_repository_id': collection.repository_id).
      where(ocred_at: nil).
      where(master_type: Binary::MasterType::ACCESS).
      where('media_type LIKE ? OR media_type = ?', 'image/%', 'application/pdf')
    binary_count = binaries.count
    num_threads  = self.class.num_threads
    self.task&.update(status_text: "Running OCR on #{binary_count} binaries "\
                                   "in #{collection.title} using #{num_threads} threads")

    ThreadUtils.process_in_parallel(binaries,
                                    num_threads: num_threads,
                                    task: self.task) do |binary|
      binary.detect_text
      binary.save!
      binary.item.reindex
    end
  end

end
