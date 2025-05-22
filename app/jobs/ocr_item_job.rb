##
# Runs OCR against the relevant binaries attached to an item and all of its
# child items.
#
class OcrItemJob < ApplicationJob # TODO: replace this with OcrItemsJob

  QUEUE = ApplicationJob::Queue::ADMIN

  queue_as QUEUE

  ##
  # The number of threads is limited mainly by:
  #
  # 1. The AWS Lambda concurrent invocation limit (which is in the thousands)
  # 2. The database connection pool size (probably a lot smaller than #1)
  # 3. Indexing performance of OpenSearch
  #
  # As the way the production environment is currently configured, the greatest
  # limiter is #3, followed by #2.
  #
  # As far as #2 goes, we must consider that {Task} uses its own connection
  # pool, which halves the number of threads we can use. Also we must remember
  # to leave some spare connections for our job worker itself.
  #
  # @return [Integer]
  #
  def self.num_threads
    num = (ActiveRecord::Base.connection_pool.instance_eval { @size }) / 2
    num = 10 if num < 10 # any less than this and it will be too slow
    num
  end

  ##
  # Arguments:
  #
  # 1. `:user`: {User} instance
  # 2. `:item`: {Item} instance
  # 3. `:language_code`: ISO 639-2 language code
  # 4. `:include_already_ocred`: Boolean
  #
  # @param args [Hash]
  #
  def perform(**args)
    main_item    = args[:item]
    binaries     = main_item.ocrable_binaries(recursive: true)
    binaries     = binaries.where(ocred_at: nil) unless args[:include_already_ocred]
    binary_count = binaries.count
    num_threads  = self.class.num_threads
    self.task&.update(status_text: "Running OCR on #{binary_count} binaries "\
                                   "using #{num_threads} threads")

    ThreadUtils.process_in_parallel(binaries,
                                    num_threads: num_threads,
                                    task: self.task) do |binary|
      binary.detect_text(language: args[:language_code])
      binary.save!
      binary.item.reindex
    end
    main_item.update!(ocred: true)
  end

end
