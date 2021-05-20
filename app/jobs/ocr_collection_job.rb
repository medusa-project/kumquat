##
# Runs OCR against all relevant {Binary binaries} in a collection.
#
# @see [OcrBinaryJob]
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

    # Divide the total number of results into num_threads segments, and have
    # each thread work on a segment.
    mutex               = Mutex.new
    threads             = Set.new
    # N.B.: these conditions must be kept in sync with Binary.ocrable?()
    binaries            = Binary.joins(:item).
      where('items.collection_repository_id': collection.repository_id).
      where(full_text: nil).
      where(master_type: Binary::MasterType::ACCESS).
      where('media_type LIKE ? OR media_type = ?', 'image/%', 'application/pdf')
    binary_count        = binaries.count
    binary_index        = 0
    binaries_per_thread = (binary_count / num_threads.to_f).ceil
    return if binaries_per_thread < 1

    self.task&.update(status_text: "Running OCR on #{binary_count} "\
        "binaries in #{collection.title} using #{num_threads} threads")

    num_threads.times do |thread_num|
      threads << Thread.new do
        batch_size  = [1000, binaries_per_thread].min
        num_batches = (binaries_per_thread / batch_size.to_f).ceil
        num_batches.times do |batch_index|
          batch_offset = batch_index * batch_size
          q_offset     = thread_num * binaries_per_thread + batch_offset
          q_limit      = [batch_size, binaries_per_thread - batch_offset].min
          Binary.uncached do
            binaries.limit(q_limit).offset(q_offset).each do |binary|
              binary.detect_text
              binary.save!
              binary.item.reindex
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


  private

  def num_threads
    ActiveRecord::Base.connection_pool.instance_eval { @size }
  end

end
