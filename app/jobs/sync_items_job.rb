class SyncItemsJob < Job

  queue_as :default

  ##
  # @param args [Array] Three-element array with the UUID of the collection to
  #                     sync at position 0; one of the
  #                     MedusaIngester::IngestMode constants at position 1;
  #                     and options hash at position 2.
  #
  def perform(*args)
    collection = Collection.find_by_repository_id(args[0])

    self.task.status_text = "Syncing items in #{collection.title}"
    # Indeterminate because the sync happens in a transaction from which
    # task progress updates won't appear.
    self.task.indeterminate = true
    self.task.save!

    result = MedusaIngester.new.ingest_items(collection, args[1], args[2], [])
    Solr.instance.commit

    self.task.status_text += ": #{result[:num_created]} created; "\
        "#{result[:num_updated]} updated; "\
        "#{result[:num_deleted]} deleted; "\
        "#{result[:num_skipped]} skipped"
    self.task.succeeded
  end

end
