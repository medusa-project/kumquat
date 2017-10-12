class UpdateItemsFromTsvJob < Job

  queue_as :default

  ##
  # @param args [Array] Two-element array with the pathname of the TSV to
  #                     ingest at position 0 and its original filename at
  #                     position 1.
  #
  def perform(*args)
    self.task.update(status_text: 'Updating item metadata from TSV')

    ItemTsvUpdater.new.ingest_pathname(args[0], args[1], self.task)

    File.delete(args[0]) if File.exist?(args[0])

    self.task.succeeded
  end

end
