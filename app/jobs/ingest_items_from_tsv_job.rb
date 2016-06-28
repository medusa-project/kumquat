class IngestItemsFromTsvJob < Job

  queue_as :default

  ##
  # @param args [Array] Two-element array with the pathname of the TSV to
  #                     ingest at position 0, and the ID of the collection to
  #                     ingest the items into at position 1.
  #
  def perform(*args)
    self.task.status_text = 'Ingesting items from TSV'
    # Indeterminate because the ingest happens in a transaction from which
    # task progress updates won't appear.
    self.task.indeterminate = true
    self.task.save!

    collection = Collection.find_by_repository_id(args[1])
    ItemTsvIngester.new.ingest_pathname(args[0], collection)
    Solr.instance.commit

    File.delete(args[0]) if File.exist?(args[0])

    self.task.succeeded
  end

end
