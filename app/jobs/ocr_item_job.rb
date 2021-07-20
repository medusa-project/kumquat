##
# Runs OCR against the relevant binaries attached to an item and all of its
# child items.
#
# @see [OcrBinaryJob]
# @see [OcrCollectionJob]
#
class OcrItemJob < Job

  QUEUE = Job::Queue::ADMIN

  queue_as QUEUE

  ##
  # @return [Integer]
  #
  def self.num_threads
    # The number of threads is limited mainly by:
    #
    # 1. The AWS Lambda concurrent invocation limit (which is in the thousands)
    # 2. The database connection pool size (probably a lot smaller than [1])
    # 3. Indexing performance of Elasticsearch
    #
    # As the way the production environment is currently configured, the
    # greatest limiter is #3, followed by #2. And as far as #2 goes, we must
    # consider that Task uses its own connection pool, which halves the number
    # of threads we can use. Also we must remember to leave some spare
    # connections for Delayed Job itself.
    num = (ActiveRecord::Base.connection_pool.instance_eval { @size }) / 2
    num = 10 if num < 10 # any less than this and it will be too slow
    num
  end

  ##
  # @param args [Array] One-element array containing an item UUID.
  #
  def perform(*args)
    main_item = Item.find_by_repository_id(args[0])
    raise ActiveRecord::RecordNotFound unless main_item

    # Divide the total number of results into num_threads segments, and have
    # each thread work on a segment.
    mutex            = Mutex.new
    threads          = Set.new
    items            = [main_item] + main_item.all_children
    item_count       = items.length
    item_index       = 0
    num_threads      = self.class.num_threads
    items_per_thread = (item_count / num_threads.to_f).ceil
    return if items_per_thread < 1

    self.task&.update(status_text: "Running OCR on #{main_item.title} and "\
          "#{item_count - 1} child items using #{num_threads} threads")

    num_threads.times do |thread_num|
      threads << Thread.new do
        batch_size  = [1000, items_per_thread].min
        num_batches = (items_per_thread / batch_size.to_f).ceil
        num_batches.times do |batch_index|
          batch_offset = batch_index * batch_size
          q_offset     = thread_num * items_per_thread + batch_offset
          q_limit      = [batch_size, items_per_thread - batch_offset].min
          items[q_offset..(q_offset + q_limit)]&.each do |item|
            # N.B.: these conditions are roughly in sync with Binary.ocrable?()
            item.binaries.
                where(master_type: Binary::MasterType::ACCESS).
                where('media_type LIKE ? OR media_type = ?', 'image/%', 'application/pdf').each do |binary|
              binary.detect_text
              binary.save!
              item.reindex
              mutex.synchronize do
                item_index += 1
                self.task&.update(percent_complete: item_index / item_count.to_f)
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
