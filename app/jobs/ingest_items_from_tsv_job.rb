class IngestItemsFromTsvJob < Job

  queue_as :default

  ##
  # @param args [Array] Two-element array with the pathname of the TSV to
  #                     ingest at position 0, and the ID of the collection to
  #                     ingest the items into at position 1.
  #
  def perform(*args)
    self.task.status_text = 'Ingesting items from TSV'
    self.task.indeterminate = false
    self.task.save!

    collection = Collection.find_by_repository_id(args[1])
    ItemTsvIngester.new.ingest_tsv_file(args[0], collection, self.task)
    Solr.instance.commit

    File.delete(args[0]) if File.exist?(args[0])

    self.task.succeeded
  end

end
