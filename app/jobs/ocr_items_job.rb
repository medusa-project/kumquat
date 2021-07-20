##
# Runs OCR against multiple items..
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
    items = Item.where('repository_id IN (?)', args[0])
    binaries = []
    items.each do |item|
      binaries += item.ocrable_binaries(recursive: true)
    end

    # Divide the total number of results into num_threads segments, and have
    # each thread work on a segment.
    mutex               = Mutex.new
    threads             = Set.new
    binary_count        = binaries.count
    binary_index        = 0
    num_threads         = [self.class.num_threads, binaries.count].min
    num_errors          = 0
    binaries_per_thread = (binary_count / num_threads.to_f).ceil
    return if binaries_per_thread < 1

    status_text = "Running OCR on #{binary_count} binaries using "\
        "#{num_threads} threads"
    self.task&.update(status_text: status_text)

    num_threads.times do |thread_num|
      threads << Thread.new do
        batch_size  = [1000, binaries_per_thread].min
        num_batches = (binaries_per_thread / batch_size.to_f).ceil
        num_batches.times do |batch_index|
          batch_offset = batch_index * batch_size
          q_offset     = thread_num * binaries_per_thread + batch_offset
          q_limit      = [batch_size, binaries_per_thread - batch_offset].min
          Binary.uncached do
            batch = binaries.respond_to?(:limit) ?
                      binaries.limit(q_limit).offset(q_offset) :
                      binaries[q_offset..q_limit]
            batch.each do |binary|
              begin
                binary.detect_text
                binary.save!
                binary.item.reindex
              rescue
                num_errors += 1
                self.task&.update(status_text: "#{status_text} (#{num_errors} errors)")
                LOGGER.error("Failed to run OCR on binary UUID %s",
                             binary.medusa_uuid)
              end
              mutex.synchronize do
                binary_index += 1
                self.task&.update(percent_complete: binary_index / binary_count.to_f)
              end
            end
          end
        end
      end
    end
    threads.each(&:join)
    self.task&.succeeded
  end

end
