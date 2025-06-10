##
# Runs OCR against one or more items and their children.
#
class OcrItemsJob < ApplicationJob

  LOGGER = CustomLogger.new(OcrItemsJob)
  QUEUE  = ApplicationJob::Queue::ADMIN

  queue_as QUEUE

  def self.num_threads
    OcrItemJob.num_threads
  end

  ##
  # Arguments:
  #
  # 1. `:user`: {User} instance
  # 2. `:item_ids`: Array of {Item} UUIDs
  # 3. `:language_code`: ISO 639-2 language code
  # 4. `:include_already_ocred`: Boolean
  #
  # @param args [Hash]
  #
  def perform(**args)
    # N.B.: these conditions must be kept in sync with Binary.ocrable?()
    binaries = Binary.joins(:item).
      where('items.repository_id IN (?)
          OR items.parent_repository_id IN (?)', args[:item_ids], args[:item_ids]).
      where(master_type: Binary::MasterType::ACCESS).
      where('media_type LIKE ? OR media_type = ?', 'image/%', 'application/pdf')
    binaries = binaries.where(ocred_at: nil) unless args[:include_already_ocred]

    num_threads = self.class.num_threads
    self.task&.update(status_text: "Running OCR on #{binaries.count} "\
                                   "binaries using #{num_threads} threads")

    ThreadUtils.process_in_parallel(binaries,
                                    num_threads: num_threads,
                                    task: self.task) do |binary|
      binary.detect_text(language: args[:language_code])
      binary.ocred_at = Time.current 
      binary.save!
      binary.item.reindex
    end
    Item.where(repository_id: args[:item_ids]).update_all(ocred: true)
  end

end
