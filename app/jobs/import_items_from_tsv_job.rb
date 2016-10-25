class ImportItemsFromTsvJob < Job

  queue_as :default

  ##
  # @param args [Array] One-element array with the pathname of the TSV to
  #                     ingest at position 0.
  #
  def perform(*args)
    self.task.update(status_text: 'Importing items from TSV')

    ItemTsvIngester.new.ingest_pathname(args[0], self.task)
    Solr.instance.commit

    File.delete(args[0]) if File.exist?(args[0])

    self.task.succeeded
  end

end
