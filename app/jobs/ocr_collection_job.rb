##
# Runs OCR against all relevant {Binary binaries} in a collection.
#
class OcrCollectionJob < ApplicationJob

  LOGGER = CustomLogger.new(OcrCollectionJob)
  QUEUE  = ApplicationJob::Queue::ADMIN

  queue_as QUEUE

  def self.num_threads
    OcrItemJob.num_threads
  end

  ##
  # Arguments:
  #
  # 1. `:user`: {User} instance
  # 2. `:collection`: {Collection} instance
  # 3. `:language_code`: ISO 639-2 language code
  # 4. `:include_already_ocred`: Boolean
  #
  # @param args [Hash]
  #
  def perform(**args)
    collection = args[:collection]

    # N.B.: these conditions must be kept in sync with Binary.ocrable?()
    binaries     = Binary.joins(:item).
      where('items.collection_repository_id': collection.repository_id).
      where(master_type: Binary::MasterType::ACCESS).
      where('media_type LIKE ? OR media_type = ?', 'image/%', 'application/pdf')
    binaries = binaries.where(ocred_at: nil) unless args[:include_already_ocred]
    binary_count = binaries.count
    num_threads  = self.class.num_threads
    self.task&.update(status_text: "Running OCR on #{binary_count} binaries "\
                                   "in #{collection.title} using #{num_threads} threads")

    ThreadUtils.process_in_parallel(binaries,
                                    num_threads: num_threads,
                                    task: self.task) do |binary|
      binary.detect_text(language: args[:language_code])
      binary.save!
      binary.item.reindex
    end
    collection.items.update!(ocred: true)
  end

end
