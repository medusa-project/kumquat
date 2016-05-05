class IngestItemsFromTsvJob < Job

  queue_as :default

  ##
  # @param args [Array] One-element array containing a pathname of the TSV to
  #                     ingest.
  #
  def perform(*args)
    self.task.status_text = 'Ingesting items from TSV'
    self.task.indeterminate = false
    self.task.save!

    ItemTsvIngester.new.ingest_tsv_file(args[0], self.task)
    Solr.instance.commit

    File.delete(args[0]) if File.exist?(args[0])

    self.task.succeeded
  end

end
