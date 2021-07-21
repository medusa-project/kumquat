##
# Runs OCR against one or more items and their children.
#
class OcrItemsJob < Job

  LOGGER = CustomLogger.new(OcrItemsJob)
  QUEUE  = Job::Queue::ADMIN

  queue_as QUEUE

  def self.num_threads
    OcrItemJob.num_threads
  end

  ##
  # @param args [Array] One-element array containing an array of item UUIDs.
  #
  def perform(*args)
    # N.B.: these conditions must be kept in sync with Binary.ocrable?()
    binaries = Binary.joins(:item).
      where('items.repository_id IN (?)
          OR items.parent_repository_id IN (?)', args[0], args[0]).
      where(master_type: Binary::MasterType::ACCESS).
      where('media_type LIKE ? OR media_type = ?', 'image/%', 'application/pdf')

    num_threads = self.class.num_threads
    self.task&.update(status_text: "Running OCR on #{binaries.count} "\
                                   "binaries using #{num_threads} threads")

    ThreadUtils.process_in_parallel(binaries,
                                    num_threads: num_threads,
                                    task: self.task) do |binary|
      binary.detect_text
      binary.save!
      binary.item.reindex
    end
  end

end
